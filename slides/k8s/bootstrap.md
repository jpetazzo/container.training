# TLS bootstrap

- kubelet needs TLS keys and certificates to communicate with the control plane

- How do we generate this information?

- How do we make it available to kubelet?

---

## Option 1: push

- When we want to provision a node:

  - generate its keys, certificate, and sign centrally

  - push the files to the node

- OK for "traditional", on-premises deployments

- Not OK for cloud deployments with auto-scaling

---

## Option 2: poll + push

- Discover nodes when they are created

  (e.g. with cloud API)

- When we detect a new node, push TLS material to the node

  (like in option 1)

- It works, but:

  - discovery code is specific to each provider

  - relies heavily on the cloud provider API

  - doesn't work on-premises

  - doesn't scale

---

## Option 3: bootstrap tokens + CSR API

- Since Kubernetes 1.4, the Kubernetes API supports CSR

  (Certificate Signing Requests)

- This is similar to the protocol used to obtain e.g. HTTPS certificates:

  - subject (here, kubelet) generates TLS keys and CSR

  - subject submits CSR to CA

  - CA validates (or not) the CSR

  - CA sends back signed certificate to subject

- This is combined with *bootstrap tokens*

---

## Bootstrap tokens

- A [bootstrap token](https://kubernetes.io/docs/reference/access-authn-authz/bootstrap-tokens/) is an API access token

  - it is a Secret with type `bootstrap.kubernetes.io/token`

  - it is 6 public characters (ID) + 16 secret characters
    <br/>(example: `whd3pq.d1ushuf6ccisjacu`)

  - it gives access to groups `system:bootstrap:<ID>` and `system:bootstrappers`
   
   - additional groups can be specified in the Secret

---

## Bootstrap tokens with kubeadm

- kubeadm automatically creates a bootstrap token

  (it is shown at the end of `kubeadm init`)

- That token adds the group `system:bootstrappers:kubeadm:default-node-token`

- kubeadm also creates a ClusterRoleBinding `kubeadm:kubelet-bootstrap`
  <br/>binding `...:default-node-token` to ClusterRole `system:node-bootstrapper`

- That ClusterRole gives create/get/list/watch permissions on the CSR API

---

## Bootstrap tokens in practice

- Let's list our bootstrap tokens on a cluster created with kubeadm

.lab[

- Log into node `test1`

- View bootstrap tokens:
  ```bash
  sudo kubeadm token list
  ```

]

- Tokens are short-lived

- We can create new tokens with `kubeadm` if necessary

---

class: extra-details

## Retrieving bootstrap tokens with kubectl

- Bootstrap tokens are Secrets with type `bootstrap.kubernetes.io/token`

- Token ID and secret are in data fields `token-id` and `token-secret`

- In Secrets, data fields are encoded with Base64

- This "very simple" command will show us the tokens:

```
kubectl -n kube-system get secrets -o json | 
        jq -r '.items[] 
        | select(.type=="bootstrap.kubernetes.io/token")
        | ( .data["token-id"] + "Lg==" + .data["token-secret"] + "Cg==")
        ' | base64 -d
```

(On recent versions of `jq`, you can simplify by using filter `@base64d`.)

---

class: extra-details

## Using a bootstrap token

- The token we need to use has the form `abcdef.1234567890abcdef`

.lab[

- Check that it is accepted by the API server:
  ```bash
  curl -k -H "Authorization: Bearer abcdef.1234567890abcdef"
  ```

- We should see that we are *authenticated* but not *authorized*:
  ```
  User \"system:bootstrap:abcdef\" cannot get path \"/\""
  ```

- Check that we can access the CSR API:
  ```bash
  curl -k -H "Authorization: Bearer abcdef.1234567890abcdef" \
       https://10.96.0.1/apis/certificates.k8s.io/v1/certificatesigningrequests
  ```

]

---

## The cluster-info ConfigMap

- Before we can talk to the API, we need:

  - the API server address (obviously!)

  - the cluster CA certificate

- That information is stored in a public ConfigMap

.lab[

- Retrieve that ConfigMap:
  ```bash
  curl -k https://10.96.0.1/api/v1/namespaces/kube-public/configmaps/cluster-info
  ```

]

*Extracting the kubeconfig file is left as an exercise for the reader.*

---

class: extra-details

## Signature of the config-map

- You might have noticed a few `jws-kubeconfig-...` fields

- These are config-map signatures

  (so that the client can protect against MITM attacks)

- These are JWS signatures using HMAC-SHA256

  (see [here](https://kubernetes.io/docs/reference/access-authn-authz/bootstrap-tokens/#configmap-signing) for more details)

---

## Putting it all together

This is the TLS bootstrap mechanism, step by step.

- The node uses the cluster-info ConfigMap to get the cluster CA certificate

- The node generates its keys and CSR

- Using the bootstrap token, the node creates a CertificateSigningRequest object

- The node watches the CSR object

- The CSR object is accepted (automatically or by an admin)

- The node gets notified, and retrieves the certificate

- The node can now join the cluster

---

## Bottom line

- If you paid attention, we still need a way to:

  - either safely get the bootstrap token to the nodes

  - or disable auto-approval and manually approve the nodes when they join

- The goal of the TLS bootstrap mechanism is *not* to solve this

  (in terms of information knowledge, it's fundamentally impossible!)

- But it reduces the differences between environments, infrastructures, providers ...

- It gives a mechanism that is easier to use, and flexible enough, for most scenarios

---

## More information

- As always, the Kubernetes documentation has extra details:

  - [TLS management](https://kubernetes.io/docs/tasks/tls/managing-tls-in-a-cluster/)

  - [Authenticating with bootstrap tokens](https://kubernetes.io/docs/reference/access-authn-authz/bootstrap-tokens/)

  - [TLS bootstrapping](https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet-tls-bootstrapping/)

  - [kubeadm token](https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-token/) command

  - [kubeadm join](https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-join/) command (has details about [the join workflow](https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-join/#join-workflow))

???

:EN:- Leveraging TLS bootstrap to join nodes
:FR:- Ajout de nœuds grâce au *TLS bootstrap*
