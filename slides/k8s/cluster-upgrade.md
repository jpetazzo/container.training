# Upgrading clusters

- It's *recommended* to run consistent versions across a cluster

  (mostly to have feature parity and latest security updates)

- It's not *mandatory*

  (otherwise, cluster upgrades would be a nightmare!)

- Components can be upgraded one at a time without problems

---

## Checking what we're running

- It's easy to check the version for the API server

.exercise[

- Log into node `test1`

- Check the version of kubectl and of the API server:
  ```bash
  kubectl version
  ```

]

- In a HA setup with multiple API servers, they can have different versions

- Running the command above multiple times can return different values

---

## Node versions

- It's also easy to check the version of kubelet

.exercise[

- Check node versions (includes kubelet, kernel, container engine):
  ```bash
  kubectl get nodes -o wide
  ```

]

- Different nodes can run different kubelet versions

- Different nodes can run different kernel versions

- Different nodes can run different container engines

---

## Control plane versions

- If the control plane is self-hosted (running in pods), we can check it

.exercise[

- Show image versions for all pods in `kube-system` namespace:
  ```bash
    kubectl --namespace=kube-system get pods -o json \
            | jq -r '
              .items[]
              | [.spec.nodeName, .metadata.name]
                + 
                (.spec.containers[].image | split(":"))
              | @tsv
              ' \
            | column -t
  ```

]

---

## What version are we running anyway?

- When I say, "I'm running Kubernetes 1.11", is that the version of:

  - kubectl

  - API server

  - kubelet

  - controller manager

  - something else?

---

## Other versions that are important

- etcd

- kube-dns or CoreDNS

- CNI plugin(s)

- Network controller, network policy controller

- Container engine

- Linux kernel

---

## General guidelines

- To update a component, use whatever was used to install it

- If it's a distro package, update that distro package

- If it's a container or pod, update that container or pod

- If you used configuration management, update with that

---

## Know where your binaries come from

- Sometimes, we need to upgrade *quickly*

  (when a vulnerability is announced and patched)

- If we are using an installer, we should:

  - make sure it's using upstream packages

  - or make sure that whatever packages it uses are current

  - make sure we can tell it to pin specific component versions

---

## In practice

- We are going to update a few cluster components

- We will change the kubelet version on one node

- We will change the version of the API server

- We will work with cluster `test` (nodes `test1`, `test2`, `test3`)

---

## Updating kubelet

- These nodes have been installed using the official Kubernetes packages

- We can therefore use `apt` or `apt-get`

.exercise[

- Log into node `test3`

- View available versions for package `kubelet`:
  ```bash
  apt show kubelet -a | grep ^Version
  ```

- Upgrade kubelet:
  ```bash
  apt install kubelet=1.14.2-00
  ```

]

---

## Checking what we've done

.exercise[

- Log into node `test1`

- Check node versions:
  ```bash
  kubectl get nodes -o wide
  ```

- Create a deployment and scale it to make sure that the node still works

]

---

## Updating the API server

- This cluster has been deployed with kubeadm

- The control plane runs in *static pods*

- These pods are started automatically by kubelet

  (even when kubelet can't contact the API server)

- They are defined in YAML files in `/etc/kubernetes/manifests`

  (this path is set by a kubelet command-line flag)

- kubelet automatically updates the pods when the files are changed

---

## Changing the API server version

- We will edit the YAML file to use a different image version

.exercise[

- Log into node `test1`

- Check API server version:
  ```bash
  kubectl version
  ```

- Edit the API server pod manifest:
  ```bash
  sudo vim /etc/kubernetes/manifests/kube-apiserver.yaml
  ```

- Look for the `image:` line, and update it to e.g. `v1.14.0`

]

---

## Checking what we've done

- The API server will be briefly unavailable while kubelet restarts it

.exercise[

- Check the API server version:
  ```bash
  kubectl version
  ```

]

---

## Updating the whole control plane

- As an example, we'll use kubeadm to upgrade the entire control plane

  (note: this is possible only because the cluster was installed with kubeadm)

.exercise[

- Check what will be upgraded:
  ```bash
  sudo kubeadm upgrade plan
  ```

  (Note: kubeadm is confused by our manual upgrade of the API server.
  <br/>It thinks the cluster is running 1.14.0!)

<!-- ##VERSION## -->

- Perform the upgrade:
  ```bash
  sudo kubeadm upgrade apply v1.14.2
  ```

]

---

## Updating kubelets

- After updating the control plane, we need to update each kubelet

- This requires to run a special command on each node, to download the config

  (this config is generated by kubeadm)

.exercise[

- Download the configuration on each node, and upgrade kubelet:
  ```bash
    for N in 1 2 3; do
    	ssh node$N sudo kubeadm upgrade node config --kubelet-version v1.14.2
  	  ssh node $N sudo apt install kubelet=1.14.2-00
    done
  ```
]

---

## Checking what we've done

- All our nodes should now be updated to version 1.14.2

.exercise[

- Check nodes versions:
  ```bash
  kubectl get nodes -o wide
  ```

]
