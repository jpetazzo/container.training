# Building a 1-node cluster

- Ingredients: a Linux machine with...

  - Ubuntu LTS

  - Kubernetes, etcd, and CNI binaries installed

  - nothing is running

---

## The plan

1. Start API server

2. Interact with it (create Deployment and Service)

3. See what's broken

4. Fix it and go back to step 2 until it works!

---

## Starting API server

.lab[

- Try to start the API server:
  ```bash
  kube-apiserver
  # It will complain about permission to /var/run/kubernetes

  sudo kube-apiserver
  # Now it will complain about a bunch of missing flags, including:
  # --etcd-servers
  # --service-account-issuer
  # --service-account-signing-key-file
  ```

]

We'll need to start etcd.

But we'll also need some TLS keys!

---

## Generating TLS keys

- There are many ways to generate TLS keys (and certificates)

- A very popular and modern tool to do that is [cfssl]

- We're going to use the old-fashioned [openssl] CLI

- Feel free to use cfssl or any other tool if you prefer!

[cfssl]: https://github.com/cloudflare/cfssl#using-the-command-line-tool
[openssl]: https://www.openssl.org/docs/man3.0/man1/

---

## How many keys do we need?

At the very least, we need the following two keys:

- ServiceAccount key pair

- API client key pair, aka "CA key"

  (technically, we will need a *certificate* for that key pair)

But if we wanted to tighten the cluster security, we'd need many more...

---

## The other keys

These keys are not strictly necessary at this point:

- etcd key pair

  *without that key, communication with etcd will be insecure*

- API server endpoint key pair

  *the API server will generate this one automatically if we don't*

- kubelet key pair (used by API server to connect to kubelets)

  *without that key, commands like kubectl logs/exec will be insecure*

---

## Would you like some auth with that?

If we want to enable authentication and authorization, we also need various API client key pairs signed by the "CA key" mentioned earlier. That would include (non-exhaustive list):

- controller manager key pair

- scheduler key pair

- in most cases: kube-proxy (or equivalent) key pair

- in most cases: key pairs for the nodes joining the cluster

  (these might be generated through TLS bootstrap tokens)

- key pairs for users that will interact with the clusters

  (unless another authentication mechanism like OIDC is used)

---

## Generating our keys and certificates

.lab[

- Generate the ServiceAccount key pair:
  ```bash
  openssl genrsa -out sa.key 2048
  ```

- Generate the CA key pair:
  ```bash
  openssl genrsa -out ca.key 2048
  ```

- Generate a self-signed certificate for the CA key:
  ```bash
  openssl x509 -new -key ca.key -out ca.cert -subj /CN=kubernetes/
  ```

]

---

## Starting etcd

- This one is easy!

.lab[

- Start etcd:
  ```bash
  etcd
  ```

]

Note: if you want a bit of extra challenge, you can try
to generate the etcd key pair and use it.

(You will need to pass it to etcd and to the API server.)

---

## Starting API server

- We need to use the keys and certificate that we just generated

.lab[

- Start the API server:
  ```bash
  sudo kube-apiserver \
  	--etcd-servers=http://localhost:2379 \
  	--service-account-signing-key-file=sa.key \
  	--service-account-issuer=https://kubernetes \
  	--service-account-key-file=sa.key \
  	--client-ca-file=ca.cert
  ```

]

The API server should now start.

But can we really use it? 🤔

---

## Trying `kubectl`

- Let's try some simple `kubectl` command

.lab[

- Try to list Namespaces:
  ```bash
  kubectl get namespaces
  ```

]

We're getting an error message like this one:

```
The connection to the server localhost:8080 was refused -
did you specify the right host or port?
```

---

## What's going on?

- Recent versions of Kubernetes don't support unauthenticated API access

- The API server doesn't support listening on plain HTTP anymore

- `kubectl` still tries to connect to `localhost:8080` by default

- But there is nothing listening there

- Our API server listens on port 6443, using TLS

---

## Trying to access the API server

- Let's use `curl` first to confirm that everything works correctly

  (and then we will move to `kubectl`)

.lab[

- Try to connect with `curl`:
  ```bash
  curl https://localhost:6443
  # This will fail because the API server certificate is unknown.
  ```

- Try again, skipping certificate verification:
  ```bash
  curl --insecure https://localhost:6443
  ```

]

We should now see an `Unauthorized` Kubernetes API error message.
</br>
We need to authenticate with our key and certificate.

---

## Authenticating with the API server

- For the time being, we can use the CA key and cert directly

- In a real world scenario, we would *never* do that!

  (because we don't want the CA key to be out there in the wild)

.lab[

- Try again, skipping cert verification, and using the CA key and cert:
  ```bash
  curl --insecure --key ca.key --cert ca.cert https://localhost:6443
  ```

]

We should see a list of API routes.

---

class: extra-details

## Doing it right

In the future, instead of using the CA key and certificate,
we should generate a new key, and a certificate for that key,
signed by the CA key.

Then we can use that new key and certificate to authenticate.

Example:

```
### Generate a key pair
openssl genrsa -out user.key

### Extract the public key
openssl pkey -in user.key -out user.pub -pubout

### Generate a certificate signed by the CA key
openssl x509 -new -key ca.key -force_pubkey user.pub -out user.cert \
        -subj /CN=kubernetes-user/
```

---

## Writing a kubeconfig file

- We now want to use `kubectl` instead of `curl`

- We'll need to write a kubeconfig file for `kubectl`

- There are many way to do that; here, we're going to use `kubectl config`

- We'll need to:

  - set the "cluster" (API server endpoint)

  - set the "credentials" (the key and certficate)

  - set the "context" (referencing the cluster and credentials)

  - use that context (make it the default that `kubectl` will use)

---

## Set the cluster

The "cluster" section holds the API server endpoint.

.lab[

- Set the API server endpoint:
  ```bash
  kubectl config set-cluster polykube --server=https://localhost:6443
  ```

- Don't verify the API server certificate:
  ```bash
  kubectl config set-cluster polykube --insecure-skip-tls-verify
  ```

]

---

## Set the credentials

The "credentials" section can hold a TLS key and certificate, or a token, or configuration information for a plugin (for instance, when using AWS EKS or GCP GKE, they use a plugin).

.lab[

- Set the client key and certificate:
  ```bash
  kubectl config set-credentials polykube \
  			--client-key ca.key \
  			--client-certificate ca.cert 
  ```

]

---

## Set and use the context

The "context" section references the "cluster" and "credentials" that we defined earlier.

(It can also optionally reference a Namespace.)

.lab[

- Set the "context":
  ```bash
  kubectl config set-context polykube --cluster polykube --user polykube
  ```

- Set that context to be the default context:
  ```bash
  kubectl config use-context polykube
  ```

]

---

## Review the kubeconfig file

The kubeconfig file should look like this:

.small[
```yaml
apiVersion: v1
clusters:
- cluster:
    insecure-skip-tls-verify: true
    server: https://localhost:6443
  name: polykube
contexts:
- context:
    cluster: polykube
    user: polykube
  name: polykube
current-context: polykube
kind: Config
preferences: {}
users:
- name: polykube
  user:
    client-certificate: /root/ca.cert
    client-key: /root/ca.key
```
]

---

## Trying the kubeconfig file

- We should now be able to access our cluster's API!

.lab[

- Try to list Namespaces:
  ```bash
  kubectl get namespaces
  ```
]

This should show the classic `default`, `kube-system`, etc.

---

class: extra-details

## Do we need `--client-ca-file` ?

Technically, we didn't need to specify the `--client-ca-file` flag!

But without that flag, no client can be authenticated.

Which means that we wouldn't be able to issue any API request!

---

## Running pods

- We can now try to create a Deployment

.lab[

- Create a Deployment:
  ```bash
  kubectl create deployment blue --image=jpetazzo/color
  ```

- Check the results:
  ```bash
  kubectl get deployments,replicasets,pods
  ```

]

Our Deployment exists, but not the Replica Set or Pod.

We need to run the controller manager.

---

## Running the controller manager

- Previously, we used the `--master` flag to pass the API server address

- Now, we need to authenticate properly

- The simplest way at this point is probably to use the same kubeconfig file!

.lab[

- Start the controller manager:
  ```bash
  kube-controller-manager --kubeconfig .kube/config
  ```

- Check the results:
  ```bash
  kubectl get deployments,replicasets,pods
  ```

]

---

## What's next?

- Normally, the last commands showed us a Pod in `Pending` state

- We need two things to continue:

  - the scheduler (to assign the Pod to a Node)

  - a Node!

- We're going to run `kubelet` to register the Node with the cluster

---

## Running `kubelet`

- Let's try to run `kubelet` and see what happens!

.lab[

- Start `kubelet`:
  ```bash
  sudo kubelet
  ```

]

We should see an error about connecting to `containerd.sock`.

We need to run a container engine!

(For instance, `containerd`.)

---

## Running `containerd`

- We need to install and start `containerd`

- You could try another engine if you wanted

  (but there might be complications!)

.lab[

- Install `containerd`:
  ```bash
  sudo apt-get install containerd
  ```

- Start `containerd`:
  ```bash
  sudo containerd
  ```

]

---

class: extra-details

## Configuring `containerd`

Depending on how we install `containerd`, it might need a bit of extra configuration.

Watch for the following symptoms:

- `containerd` refuses to start

  (rare, unless there is an *invalid* configuration)

- `containerd` starts but `kubelet` can't connect

  (could be the case if the configuration disables the CRI socket)

- `containerd` starts and things work but Pods keep being killed

  (may happen if there is a mismatch in the cgroups driver)

---

## Starting `kubelet` for good

- Now that `containerd` is running, `kubelet` should start!

.lab[

- Try to start `kubelet`:
  ```bash
  sudo kubelet
  ```

- In another terminal, check if our Node is now visible:
  ```bash
  sudo kubectl get nodes
  ```

]

`kubelet` should now start, but our Node doesn't show up in `kubectl get nodes`!

This is because without a kubeconfig file, `kubelet` runs in standalone mode:
<br/>
it will not connect to a Kubernetes API server, and will only start *static pods*.

---

## Passing the kubeconfig file

- Let's start `kubelet` again, with our kubeconfig file

.lab[

- Stop `kubelet` (e.g. with `Ctrl-C`)

- Restart it with the kubeconfig file:
  ```bash
  sudo kubelet --kubeconfig .kube/config
  ```

- Check our list of Nodes:
  ```bash
  kubectl get nodes
  ```

]

This time, our Node should show up!

---

## Node readiness

- However, our Node shows up as `NotReady`

- If we wait a few minutes, the `kubelet` logs will tell us why:

  *we're missing a CNI configuration!*

- As a result, the containers can't be connected to the network

- `kubelet` detects that and doesn't become `Ready` until this is fixed

---

## CNI configuration

- We need to provide a CNI configuration

- This is a file in `/etc/cni/net.d`

  (the name of the file doesn't matter; the first file in lexicographic order will be used)

- Usually, when installing a "CNI plugin¹", this file gets installed automatically

- Here, we are going to write that file manually

.footnote[¹Technically, a *pod network*; typically running as a DaemonSet, which will install the file with a `hostPath` volume.]

---

## Our CNI configuration

Create the following file in e.g. `/etc/cni/net.d/kube.conf`:

```json
{
  "cniVersion": "0.3.1",
  "name": "kube",
  "type": "bridge",
  "bridge": "cni0",
  "isDefaultGateway": true,
  "ipMasq": true,
  "hairpinMode": true,
  "ipam": {
    "type": "host-local",
    "subnet": "10.1.1.0/24"
  }
}
```

That's all we need - `kubelet` will detect and validate the file automatically!

---

## Checking our Node again

- After a short time (typically about 10 seconds) the Node should be `Ready`

.lab[

- Wait until the Node is `Ready`:
  ```bash
  kubectl get nodes
  ```

]

If the Node doesn't show up as `Ready`, check the `kubelet` logs.

---

## What's next?

- At this point, we have a `Pending` Pod and a `Ready` Node

- All we need is the scheduler to bind the former to the latter

.lab[

- Run the scheduler:
  ```bash
  kube-scheduler --kubeconfig .kube/config
  ```

- Check that the Pod gets assigned to the Node and becomes `Running`:
  ```bash
  kubectl get pods
  ```

]

---

## Check network access

- Let's check that we can connect to our Pod, and that the Pod can connect outside

.lab[

- Get the Pod's IP address:
  ```bash
  kubectl get pods -o wide
  ```

- Connect to the Pod (make sure to update the IP address):
  ```bash
  curl `10.1.1.2`
  ```

- Check that the Pod has external connectivity too:
  ```bash
  kubectl exec `blue-xxxxxxxxxx-yyyyy` -- ping -c3 1.1
  ```

]

---

## Expose our Deployment

- We can now try to expose the Deployment and connect to the ClusterIP

.lab[

- Expose the Deployment:
  ```bash
  kubectl expose deployment blue --port=80
  ```

- Retrieve the ClusterIP:
  ```bash
  kubectl get services
  ```

- Try to connect to the ClusterIP:
  ```bash
  curl `10.0.0.42`
  ```
]

At this point, it won't work - we need to run `kube-proxy`!

---

## Running `kube-proxy`

- We need to run `kube-proxy`

  (also passing it our kubeconfig file)

.lab[

- Run `kube-proxy`:
  ```bash
  sudo kube-proxy --kubeconfig .kube/config
  ```

- Try again to connect to the ClusterIP:
  ```bash
  curl `10.0.0.42`
  ```

]

This time, it should work.

---

## What's next?

- Scale up the Deployment, and check that load balancing works properly 

- Enable RBAC, and generate individual certificates for each controller

  (check the [certificate paths][certpath] section in the Kubernetes documentation
  for a detailed list of all the certificates and keys that are used by the
  control plane, and which flags are used by which components to configure them!)

- Add more nodes to the cluster

*Feel free to try these if you want to get additional hands-on experience!*

[certpath]: https://kubernetes.io/docs/setup/best-practices/certificates/#certificate-paths

???

:EN:- Setting up control plane certificates
:EN:- Implementing a basic CNI configuration
:FR:- Mettre en place les certificats du plan de contrôle
:FR:- Réaliser un configuration CNI basique
