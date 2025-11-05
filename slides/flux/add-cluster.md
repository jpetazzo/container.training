
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

![Running Mario](images/running-mario.gif)

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
</br>https://github.com/kubernetes/ingress-nginx/tree/release-1.14/deploy/static/provider/baremetal

- In the 📄file `./clusters/METAL/ingress-nginx/sync.yaml`,
  </br>change the `Kustomization` value `spec.path: ./deploy/static/provider/baremetal`

---

class: pic

![Running Mario](images/running-mario.gif)

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

