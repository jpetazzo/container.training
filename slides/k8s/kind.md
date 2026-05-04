# Working with KinD

- Kubernetes-in-Docker

- One of the many options to run local clusters

  (like Colima, Docker Desktop, k3d, Minikube, Podman Desktop...)

- Runs Kubernetes nodes inside Docker containers

  (also works with other container engines)

- Based on kubeadm

---

## Pros

- Create a cluster in less than 1 minute

- Run multiple clusters side by side

- Clusters can have 1 or multiple nodes

- Select Kubernetes version to use

  (great to test regressions, upgrades...)

- Supports port mapping (more on that later)

- Very close to "upstream Kubernetes"

  (typically runs "normal" Kubernetes binaries)

---

## Cons

- Requires a container engine

  (Docker, Podman...)

- Port mapping can only be configured at cluster creation time

  (more on that later)

- Releases can lag a bit behind Kubernetes "latest" releases

- Not a lot of pre-installed bells and whistles

  (e.g. no ingress controller, no metrics server...)

---

## Getting started

- Creating a cluster:
  ```bash
  kind create cluster
  ```

- Cluster will be automatically added to your kubeconfig file

- See it running with `docker ps`

- Deleting a cluster:
  ```bash
  kind delete cluster
  ```

---

## Customizing the cluster

- This is done with a configuration file

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  image: kindest/node:v1.34.3
  extraPortMappings:
  - containerPort: 31234
    hostPort: 10000
- role: worker
  image: kindest/node:v1.34.3
```

- And then: `kind create cluster --config XXX.yaml`

---

## Accessing internal apps

- There are many ways to access apps running in a KinD cluster

- We'll review some of them, with their pros/cons!

---

## `kubectl port-forward`

- Works everywhere (local or remote, dev or prod...)

- Gated by RBAC with `pod/port-forward` subresource

- Inconvenient when accessing multiple services

- Inconvenient when working in Ingress or Gateway API

---

## NodePorts

- Use `NodePort` services

- Plan A: access them with the node IP address

  *does not work when the Docker host is a separate VM (e.g. with Docker Desktop)*

- Plan B: configure KinD to map extra ports

  *works everywhere; but needs some prep ahead of time*

---

## Example, mapping ports 80 and 443

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30080
    hostPort: 80
  - containerPort: 30443
    hostPort: 443
```

- Configure Ingress or Gateway Controllers to use NodePorts 30080 and 30443

- Use a domain like `localtest.me` that resolves to 127.0.0.1

- Create Ingress or HTTPRoute resources using `<something>.localtest.me`

---

## Variation

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
  - containerPort: 443
    hostPort: 443
```

- Configure Ingress or Gateway Controllers to use `hostNetwork` or `hostPort`

---

## Example, mapping a range of ports

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: ClusterConfiguration
    apiServer:
      extraArgs:
        service-node-port-range: "12301-12309"
  extraPortMappings:
  - { containerPort: 12301, hostPort: 12301 }
  - { containerPort: 12302, hostPort: 12302 }
  ...
  - { containerPort: 12308, hostPort: 12308 }
  - { containerPort: 12309, hostPort: 12309 }
```

(@@LINK[k8s/kind-12300.yaml])

---

## Other noteworthy features

- [Extra mounts][kind-extra-mounts] to expose local files to pods

- Useful for big data sets (e.g. ML model weights)

- Need to remember that there is a double mapping:

  *host → Kubernetes node in Docker container* 

  *Kubernetes node in Docker container → pod*

- Don't hesitate to use `docker exec` to get a shell in the Kubernetes node!

[kind-extra-mounts]: https://kind.sigs.k8s.io/docs/user/configuration/#extra-mounts
???

:EN:- Local dev clusters with KinD
:FR:- Cluster de dev local avec KinD
