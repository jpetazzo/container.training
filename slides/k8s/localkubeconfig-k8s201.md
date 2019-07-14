# Controlling a Kubernetes cluster remotely

- `kubectl` can be used either on cluster instances or outside the cluster

- Since we're using [AKS](https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough), we'll be running `kubectl` outside the cluster

- We can use Azure Cloud Shell

- Or we can use `kubectl` from our local machine

---

## Connecting to your AKS cluster via Azure Cloud Shell

- open portal.azure.com in a browser
- auth with the info on your card

- click `[>_]` in the top menu bar to open cloud shell

.exercise[

- get your cluster credentials:
  ```bash
  RESOURCE_GROUP=$(az group list | jq -r \
    '[.[].name|select(. | startswith("Group-"))][0]')
  AKS_NAME=$(az aks list -g $RESOURCE_GROUP | jq -r '.[0].name')
  az aks get-credentials -g $RESOURCE_GROUP -n $AKS_NAME
  ```

]

- If you're going to use Cloud Shell, you can skip ahead

---

## Connecting to your AKS cluster via local tools

.exercise[

- install the [az CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)

- log in to azure:
  ```bash
  az login
  ```


- get your cluster credentials (requires jq):
  ```bash
  RESOURCE_GROUP=$(az group list | jq -r \
    '[.[].name|select(. | startswith("Group-"))][0]')
  AKS_NAME=$(az aks list -g $RESOURCE_GROUP | jq -r '.[0].name')
  az aks get-credentials -g $RESOURCE_GROUP -n $AKS_NAME
  ```

- optionally, if you don't have kubectl:
  ```bash
  az aks install-cli
  ```

]

---

class: extra-details

## Getting started with kubectl


- `kubectl` is officially available on Linux, macOS, Windows

  (and unofficially anywhere we can build and run Go binaries)

- You may want to try Azure cloud shell if you are following along from:

  - a tablet or phone

  - a web-based terminal

  - an environment where you can't install and run new binaries

---
class: extra-details

## Installing `kubectl`

- If you already have `kubectl` on your local machine, you can skip this

.exercise[

<!-- ##VERSION## -->

- Download the `kubectl` binary from one of these links:

  [Linux](https://storage.googleapis.com/kubernetes-release/release/v1.15.0/bin/linux/amd64/kubectl)
  |
  [macOS](https://storage.googleapis.com/kubernetes-release/release/v1.15.0/bin/darwin/amd64/kubectl)
  |
  [Windows](https://storage.googleapis.com/kubernetes-release/release/v1.15.0/bin/windows/amd64/kubectl.exe)

- On Linux and macOS, make the binary executable with `chmod +x kubectl`

  (And remember to run it with `./kubectl` or move it to your `$PATH`)

]

Note: if you are following along with a different platform (e.g. Linux on an architecture different from amd64, or with a phone or tablet), installing `kubectl` might be more complicated (or even impossible) so check with us about cloud shell.


---
class: extra-details

## Preserving the existing `~/.kube/config`

- If you already have a `~/.kube/config` file, rename it

  (we are going to overwrite it in the following slides!)

- If you never used `kubectl` on your machine before: nothing to do!

.exercise[

- Make a copy of `~/.kube/config`; if you are using macOS or Linux, you can do:
  ```bash
  cp ~/.kube/config ~/.kube/config.before.training
  ```

- If you are using Windows, you will need to adapt this command

]

---

## Testing `kubectl`

- Check that `kubectl` works correctly

  (before even trying to connect to a remote cluster!)

.exercise[

- Ask `kubectl` to show its version number:
  ```bash
  kubectl version --client
  ```

]

The output should look like this:
```
Client Version: version.Info{Major:"1", Minor:"15", GitVersion:"v1.15.0",
GitCommit:"e8462b5b5dc2584fdcd18e6bcfe9f1e4d970a529", GitTreeState:"clean",
BuildDate:"2019-06-19T16:40:16Z", GoVersion:"go1.12.5", Compiler:"gc",
Platform:"darwin/amd64"}
```
---


## Let's look at your cluster!

.exercise[

- Scan for the `server:` address that matches the `name` of your new cluster
  ```bash
  kubectl config view
  ```

- Store the API endpoint you find:
  ```bash 
  API_URL=$(kubectl config view -o json | jq -r ".clusters[]  \
            | select(.name == \"$AKS_NAME\") | .cluster.server")
  echo $API_URL
]

---

class: extra-details

## What if we get a certificate error?

- Generally, the Kubernetes API uses a certificate that is valid for:

  - `kubernetes`
  - `kubernetes.default`
  - `kubernetes.default.svc`
  - `kubernetes.default.svc.cluster.local`
  - the ClusterIP address of the `kubernetes` service
  - the hostname of the node hosting the control plane
  - the IP address of the node hosting the control plane

- On most clouds, the IP address of the node is an internal IP address

- ... And we are going to connect over the external IP address

- ... And that external IP address was not used when creating the certificate!

---

class: extra-details

## Working around the certificate error

- We need to tell `kubectl` to skip TLS verification

  (only do this with testing clusters, never in production!)

- The following command will do the trick:
  ```bash
  kubectl config set-cluster $AKS_NAME --insecure-skip-tls-verify
  ```

---

## Checking that we can connect to the cluster

- We can now run a couple of trivial commands to check that all is well

.exercise[

- Check the versions of the local client and remote server:
  ```bash
  kubectl version
  ```

It is okay if you have a newer client than what is available on the server.

- View the nodes of the cluster:
  ```bash
  kubectl get nodes
  ```

]

We can now utilize the cluster exactly as if we're logged into a node, except that it's remote.
