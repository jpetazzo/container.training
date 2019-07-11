# Controlling a Kubernetes cluster remotely

- `kubectl` can be used either on cluster instances or outside the cluster

- Here, we are going to use `kubectl` from our local machine

---

## Requirements

.warning[The exercises in this chapter should be done *on your local machine*.]

- `kubectl` is officially available on Linux, macOS, Windows

  (and unofficially anywhere we can build and run Go binaries)

- You may want to try Azure cloud shell if you are following along from:

  - a tablet or phone

  - a web-based terminal

  - an environment where you can't install and run new binaries

---

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

## Connecting to your AKS cluster

[fill in]

---

## Let's look at your cluster!


- First, inspect the config
  ```bash
  kubectl config view
  ```

- Look for the `server:` address that matches your new cluster

```
- cluster:
    certificate-authority-data: DATA+OMITTED
    server: https://aks-test-c-aks-test-group-0d35f7-28c7d691.hcp.eastus.azmk8s.io:443
  name: aks-test-cluster
```

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
  kubectl config set-cluster <clustername> --insecure-skip-tls-verify
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
