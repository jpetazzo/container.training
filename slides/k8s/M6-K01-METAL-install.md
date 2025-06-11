# Installing a Kubernetes cluster from scratch

We operated a managed cluster from **Scaleway** `Kapsule`.  

It's great! Most batteries are included:

- storage classes, with an already configured default one
- a default CNI with `Cilium`
  <br/>(`Calico` is supported too)
- a _IaaS_ load-balancer that is manageable by `ingress-controllers`
- a management _WebUI_ with the Kubernetes dashboard
- an observability stack with `metrics-server` and the Kubernetes dashboard

But what about _on premises_ needs?

---

class: extra-details

## On premises Kubernetes distributions

The [CNCF landscape](https://landscape.cncf.io/?fullscreen=yes&zoom=200&group=certified-partners-and-providers) currently lists **61!** Kubernetes distributions, today.  
Not speaking of Kubernetes managed services from Cloud providers…  

Please, refer to the [`Setting up Kubernetes` chapter in the High Five M2 module](./2.yml.html#toc-setting-up-kubernetes) for more infos about Kubernetes distributions.

---

## Introducing k0s

Nowadays, some "light" distros are considered good enough to run production clusters.  
That's the case for `k0s`.

It's an open source Kubernetes lightweight distribution.  
Mainly relying on **Mirantis**, a long-time software vendor in Kubernetes ecosystem.  
(The ones who bought `Docker Enterprise` a long time ago. remember?)

`k0s` aims to be both

- a lightweight distribution for _edge-computing_ and development pupose
- an enterprise-grade HA distribution fully supported by its editor
  <br/>`MKE4` and `kordent` leverage on `k0s`

---

### `k0s` package

Its single binary includes:

- a CRI (`containerd`)
- Kubernetes vanilla control plane components (including both  `etcd`)
- a vanilla network stack
  - `kube-router`
  - `kube-proxy`
  - `coredns`
  - `konnectivity`
- `kubectl` CLI
- install / uninstall features
- backup / restore features

---

class: pic

![k0s package](images/M6-k0s-packaging.png)

---

class: extra-details

### Konnectivity

You've seen that Kubernetes cluster architecture is very versatile.  
I'm referring to the [`Kubernetes architecture` chapter in the High Five M5 module](./5.yml.html#toc-kubernetes-architecture)

Network communications between control plane components and worker nodes might be uneasy to configure.  
`Konnectivity` is a response to this pain. It acts as an RPC proxy for any communication initiated from control plane to workers.  

These communications are listed in [`Kubernetes internal APIs` chapter in the High Five M5 module](https://2025-01-enix.container.training/5.yml.html#toc-kubernetes-internal-apis)

The agent deployed on each worker node maintains an RPC tunnel with the one deployed on control plane side.

---

class: pic

![konnectivity architecture](images/M6-konnectivity-architecture.png)

---

## Installing `k0s`

It installs with a one-liner command

- either in single-node lightweight footprint
- or in multi-nodes HA footprint

.lab[

- Get the binary

```bash
docker@m621: ~$ wget https://github.com/k0sproject/k0sctl/releases/download/v0.25.1/k0sctl-linux-amd64
```

]

---

### Prepare the config file

.lab[

- Create the config file

```bash
docker@m621: ~$ k0sctl init  \
        --controller-count 3 \
        --user docker        \
        --k0s m621 m622 m623 > k0sctl.yaml
```

- change the following field: `spec.hosts[*].role: controller+worker`
- add the following fields: `spec.hosts[*].noTaints: true`

```bash
docker@m621: ~$ k0sctl apply --config k0sctl.yaml
```

]

---

### And the famous one-liner

.lab[

```bash
k8s@shpod: ~$ k0sctl apply --config k0sctl.yaml
```

]

---

### Check that k0s installed correctly

.lab[

```bash
docker@m621 ~$ sudo k0s status
Version: v1.33.1+k0s.1
Process ID: 60183
Role: controller
Workloads: true
SingleNode: false
Kube-api probing successful: true
Kube-api probing last error:  

docker@m621 ~$ sudo k0s etcd member-list
{"members":{"m621":"https://10.10.3.190:2380","m622":"https://10.10.2.92:2380","m623":"https://10.10.2.110:2380"}}
```

]

---

### `kubectl` is included

.lab[

```bash
docker@m621 ~$ sudo k0s kubectl get nodes
NAME   STATUS   ROLES           AGE   VERSION
m621   Ready    control-plane   66m   v1.33.1+k0s
m622   Ready    control-plane   66m   v1.33.1+k0s
m623   Ready    control-plane   66m   v1.33.1+k0s

docker@m621 ~$ sudo k0s kubectl run shpod --image jpetazzo/shpod

```

]

---

class: extra-details

### Single node install (for info!)

For testing purpose, you may want to use a single-node (yet `etcd`-geared) install…  

.lab[

- Install it

```bash
docker@m621 ~$ curl -sSLf https://get.k0s.sh | sudo sh
docker@m621 ~$ sudo k0s install controller --single
docker@m621 ~$ sudo k0s start
```

- Reset it

```bash
docker@m621 ~$ sudo k0s start
docker@m621 ~$ sudo k0s reset
```

]

---

## Deploying shpod

.lab[

```bash
docker@m621 ~$ sudo k0s kubectl apply -f https://shpod.in/shpod.yaml
docker@m621 ~$ sudo k0s kubectl apply -f https://shpod.in/shpod.yaml
```
]

---

## Flux install

We'll install `Flux`.  
And replay the all scenario a 2nd time.   
Let's face it: we don't have that much time. 😅

Since all our install and configuration is `GitOps`-based, we might just leverage on copy-paste and code configuration…
Maybe.

Let's copy the 📂 `./clusters/CLOUDY` folder and rename it 📂 `./clusters/METAL`.

---

### Modifying Flux config 📄 files

- In 📄 file `./clusters/METAL/flux-system/gotk-sync.yaml`
  </br>change the `Kustomization` value `spec.path: ./clusters/METAL`
    - ⚠️ We'll have to adapt the `Flux` _CLI_ command line

- And that's pretty much it!
  - We'll see if anything goes wrong on that new cluster

---

### Connecting to our dedicated `Github` repo to host Flux config

.lab[

- let's replace `GITHUB_TOKEN` and `GITHUB_REPO` values
- don't forget to change the patch to `clusters/METAL`

```bash
k8s@shpod:~$ export GITHUB_TOKEN="my-token" &&         \
      export GITHUB_USER="container-training-fleet" && \
      export GITHUB_REPO="fleet-config-using-flux-XXXXX"

k8s@shpod:~$ flux bootstrap github \
      --owner=${GITHUB_USER}       \
      --repository=${GITHUB_REPO}  \
      --team=OPS                   \
      --team=ROCKY --team=MOVY     \
      --path=clusters/METAL
```
]

---

class: pic

![Running Mario](images/M6-running-Mario.gif)

---

### Flux deployed our complete stack

Everything seems to be here but…

- one database is in `Pending` state

- our `ingresses` don't work well

```bash
k8s@shpod ~$ curl --header 'Host: rocky.test.enixdomain.com' http://${myIngressControllerSvcIP}
curl: (52) Empty reply from server
```

---

### Fixing the Ingress

The current `ingress-nginx` configuration leverages on specific annotations used by Scaleway to bind a _IaaS_ load-balancer to the `ingress-controller`.  
We don't have such kind of things here.😕

- We could bind our `ingress-controller` to a `NodePort`.
`ingress-nginx` install manifests propose it here:
</br>https://github.com/kubernetes/ingress-nginx/deploy/static/provider/baremetal

- In the 📄file `./clusters/METAL/ingress-nginx/sync.yaml`,
  </br>change the `Kustomization` value `spec.path: ./deploy/static/provider/baremetal`

---

class: pic

![Running Mario](images/M6-running-Mario.gif)

---

### Troubleshooting the database

One of our `db-0` pod is in `Pending` state.

```bash
k8s@shpod ~$ k get pods db-0 -n *-test -oyaml
(…)
status:
  conditions:
  - lastProbeTime: null
    lastTransitionTime: "2025-06-11T11:15:42Z"
    message: '0/3 nodes are available: pod has unbound immediate PersistentVolumeClaims.
      preemption: 0/3 nodes are available: 3 Preemption is not helpful for scheduling.'
    reason: Unschedulable
    status: "False"
    type: PodScheduled
  phase: Pending
  qosClass: Burstable
```

---

### Troubleshooting the PersistentVolumeClaims

```bash
k8s@shpod ~$ k get pvc postgresql-data-db-0 -n *-test -o yaml
(…)
  Type    Reason         Age                 From                         Message
  ----    ------         ----                ----                         -------
  Normal  FailedBinding  9s (x182 over 45m)  persistentvolume-controller  no persistent volumes available for this claim and no storage class is set
```

No `storage class` is available on this cluster.
We hadn't the problem on our managed cluster since a default storage class was configured and then associated to our `PersistentVolumeClaim`.

Why is there no problem with the other database?
