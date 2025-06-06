# Generating user certificates

- The most popular ways to authenticate users with Kubernetes are:

  - TLS certificates

  - JSON Web Tokens (OIDC or ServiceAccount tokens)

- We're going to see how to use TLS certificates

- We will generate a certificate for an user and give them some permissions

- Then we will use that certificate to access the cluster

---

## Heads up!

- The demos in this section require that we have access to our cluster's CA

- *On a managed cluster:* the CA is very rarely exposed by the provider

- *On a self-hosted cluster:* the CA should be available somewhere

  (it may or may not be easy to find, though!)

- We may or may not be able to use the CSR API instead

---

## Locate the CA key and cert

- On a cluster deployed with `kubeadm`:

  *the files will be in `/etc/kubernetes/pki` (on any control plane node)*

- On a cluster deployed with something like k3s or k0s:

  *Check the docs to know where the CA files are*

  *(and for extra credit, submit a PR to update this slide!)*

- On a cluster deployed manually (like "dessine-moi un cluster"):

  *the files will be wherever you did put them*

---

## Let's set environment variables

- To normalize the commands in the next slides:
  
  ```bash
  CA_KEY=/.../ca.key
  CA_CRT=/.../ca.crt
  ```

---

## How it works

- The API server is configured to accept all certificates signed by a given CA

- The certificate contains:

  - the user name (in the `CN` field)

  - the groups the user belongs to (as multiple `O` fields)

.lab[

- On clusters deployed with `kubeadm`, this will show the location of the CA cert:
  ```bash
  sudo grep client-ca /etc/kubernetes/manifests/kube-apiserver.yaml
  ```

]

This should output a flag like the following one:
```
--client-ca-file=/etc/kubernetes/pki/ca.crt
```

---

## Generating a key and CSR for our user

- These operations could be done on a separate machine

- We only need to transfer the CSR (Certificate Signing Request) to the CA

  (we never need to expose the private key)

.lab[

- Generate a private key:
  ```bash
  openssl genrsa 4096 > user.key
  ```

- Generate a CSR:
  ```bash
  openssl req -new -key user.key -subj /CN=jerome/O=devs/O=ops > user.csr
  ```

]

---

## Generating a signed certificate

- This has to be done on the machine holding the CA private key

  (copy the `user.csr` file if needed)

.lab[

- Verify the CSR paramters:
  ```bash
  openssl req -in user.csr  -text | head
  ```

- Generate the certificate:
  ```bash
  sudo openssl x509 -req \
      -CA $CA_CRT -CAkey $CA_KEY \
      -in user.csr -days 1 -set_serial 1234 > user.crt
  ```

]

If you are using two separate machines, transfer `user.crt` to the other machine.

---

## Adding the key and certificate to kubeconfig

- We have to edit our `.kube/config` file

- This can be done relatively easily with `kubectl config`

.lab[

- Create a new `user` entry in our `.kube/config` file:
  ```bash
  kubectl config set-credentials jerome \
      --client-key=user.key --client-certificate=user.crt 
  ```

]

The configuration file now points to our local files.

We could also embed the key and certs with the `--embed-certs` option.

(So that the kubeconfig file can be used without `user.key` and `user.crt`.)

---

## Using the new identity

- At the moment, we probably use the admin certificate generated by `kubeadm`

  (with `CN=kubernetes-admin` and `O=system:masters`)

- Let's edit our *context* to use our new certificate instead!

.lab[

- Edit the context:
  ```bash
  kubectl config set-context --current --user=jerome 
  ```

- Try any command:
  ```bash
  kubectl get pods
  ```

]

Does it work, or do we get a permission error?

---

## On a normal cluster

- We should get a message like the following one:
  ```
  Error from server (Forbidden): pods is forbidden: User "jerome"
  cannot list resource "pods" in API group "" in the namespace "default"
  ```

- This means:

  *your user key and cert are valid (`User "jerome"`)...*

  *...but you don't have permission to get pods yet*

- We now need to grant permissions (e.g. with Roles and Rolebindings)

---

## On a cluster deployed manually

- If we haven't enabled RBAC, then it will work

  (because without RBAC, any valid certificate gives full access to the API)

- We could (should?) enable RBAC!

- But then we'll need to generate keys and certs for all API clients

  (including, but not limited to, control plane components and kubelets)

---

## Granting permissions

- If RBAC is enabled, we can give some permissions to our new user

- The following example assumes a `kubeadm` cluster

- Let's add some read-only permissions to the `devs` group (for instance)

.lab[

- Switch back to our admin identity:
  ```bash
  kubectl config set-context --current --user=kubernetes-admin 
  ```

- Grant permissions:
  ```bash
  kubectl create clusterrolebinding devs-can-view \
      --clusterrole=view --group=devs
  ```

]

---

## Testing the new permissions

- As soon as we create the ClusterRoleBinding, all users in the `devs` group get access

- Let's verify that we can e.g. list pods!

.lab[

- Switch to our user identity again:
  ```bash
  kubectl config set-context --current --user=jerome
  ```

- Test the permissions:
  ```bash
  kubectl get pods
  ```

]

---

## `kubeadm kubeconfig user`

- On `kubeadm` clusters, there is a command to automate key and certificate generation

- `kubeadm kubeconfig user` will issue a key, certificate, and output the kubeconfig file

- It will access CA key and cert in `/etc/kubernetes/pki/` directly

???

:EN:- Authentication with user certificates
:FR:- Identification par certificat TLS
