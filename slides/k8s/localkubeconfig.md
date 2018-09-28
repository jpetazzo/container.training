# Controlling the cluster remotely

- All the operations that we do with `kubectl` can be done remotely

- In this section, we are going to use `kubectl` from our local machine

---

## Installing `kubectl`

- If you already have `kubectl` on your local machine, you can skip this

.exercise[

- Download the `kubectl` binary from one of these links:

  [Linux](https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/linux/amd64/kubectl)
  |
  [macOS](https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/darwin/amd64/kubectl)
  |
  [Windows](https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/windows/amd64/kubectl.exe)

- On Linux and macOS, make the binary executable with `chmod +x kubectl`

  (And remember to run it with `./kubectl` or move it to your `$PATH`)

]

Note: if you are following along with a different platform (e.g. Linux on an architecture different from amd64, or with a phone or tablet), installing `kubectl` might be more complicated (or even impossible) so feel free to skip this section.

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
Client Version: version.Info{Major:"1", Minor:"11", GitVersion:"v1.11.2",
GitCommit:"bb9ffb1654d4a729bb4cec18ff088eacc153c239", GitTreeState:"clean",
BuildDate:"2018-08-07T23:17:28Z", GoVersion:"go1.10.3", Compiler:"gc",
Platform:"linux/amd64"}
```

---

## Moving away the existing `~/.kube/config`

- If you already have a `~/.kube/config` file, move it away

  (we are going to overwrite it in the following slides!)

- If you never used `kubectl` on your machine before: nothing to do!

- If you already used `kubectl` to control a Kubernetes cluster before:

  - rename `~/.kube/config` to e.g. `~/.kube/config.bak`

---

## Copying the configuration file from `node1`

- The `~/.kube/config` file that is on `node1` contains all the credentials we need

- Let's copy it over!

.exercise[

- Copy the file from `node1`; if you are using macOS or Linux, you can do:
  ```
  scp `USER`@`X.X.X.X`:.kube/config ~/.kube/config
  # Make sure to replace X.X.X.X with the IP address of node1,
  # and USER with the user name used to log into node1!
  ```

- If you are using Windows, adapt these instructions to your SSH client

]

---

## Updating the server address

- There is a good chance that we need to update the server address

- To know if it is necessary, run `kubectl config view`

- Look for the `server:` address:

  - if it matches the public IP address of `node1`, you're good!

  - if it is anything else (especially a private IP address), update it!

- To update the server address, run:
  ```bash
  kubectl config set-cluster kubernetes --server=https://`X.X.X.X`:6443
  kubectl config set-cluster kubernetes --insecure-skip-tls-verify
  # Make sure to replace X.X.X.X with the IP address of node1!
  ```

---

class: extra-details

## Why do we skip TLS verification?

- Generally, the Kubernetes API uses a certificate that is valid for:

  - `kubernetes`
  - `kubernetes.default`
  - `kubernetes.default.svc`
  - `kubernetes.default.svc.cluster.local`
  - the ClusterIP address of the `kubernetes` service
  - the hostname of the node hosting the control plane (e.g. `node1`)
  - the IP address of the node hosting the control plane

- On most clouds, the IP address of the node is an internal IP address

- ... And we are going to connect over the external IP address

- ... And that external IP address was not used when creating the certificate!

.warning[It's better to NOT skip TLS verification; this is for educational purposes only!]

---

## Checking that we can connect to the cluster

- We can now run a couple of trivial commands to check that all is well

.exercise[

- Check the versions of the local client and remote server:
  ```bash
  kubectl version
  ```

- View the nodes of the cluster:
  ```bash
  kubectl get nodes
  ```

]

We can now utilize the cluster exactly as we did before, ignoring that it's remote.
