# OpenEBS 

 - [OpenEBS] is a popular open-source storage solution for Kubernetes

 - Uses the concept of "Container Attached Storage"

   (1 volume = 1 dedicated controller pod + a set of replica pods)

 - Supports a wide range of storage engines:

   - LocalPV: local volumes (hostpath or device), no replication

   - Jiva: for lighter workloads with basic cloning/snapshotting

   - cStor: more powerful engine that also supports resizing, RAID, disk pools ...

   - [Mayastor]: newer, even more powerful engine with NVMe and vhost-user support

[OpenEBS]: https://openebs.io/

[Mayastor]: https://github.com/openebs/MayaStor#mayastor

---

class: extra-details

## What are all these storage engines?

- LocalPV is great if we want good performance, no replication, easy setup

  (it is similar to the Rancher local path provisioner)

- Jiva is great if we want replication and easy setup

  (data is stored in containers' filesystems)

- cStor is more powerful and flexible, but requires more extensive setup

- Mayastor is designed to achieve extreme performance levels

  (with the right hardware and disks)

- The OpenEBS documentation has a [good comparison of engines] to help us pick

[good comparison of engines]: https://docs.openebs.io/docs/next/casengines.html#cstor-vs-jiva-vs-localpv-features-comparison

---

## Installing OpenEBS with Helm

- The OpenEBS control plane can be installed with Helm

- It will run as a set of containers on Kubernetes worker nodes

.lab[

  - Install OpenEBS:
  ```bash  
    helm upgrade --install openebs openebs \
         --repo https://openebs.github.io/charts \
         --namespace openebs --create-namespace \
         --version 2.12.9
  ```
]

⚠️ We stick to OpenEBS 2.x because 3.x requires additional configuration.

---

## Checking what was installed

- Wait a little bit ...

.lab[

- Look at the pods in the `openebs` namespace:
  ```bash  
      kubectl get pods --namespace openebs
  ```

- And the StorageClasses that were created:
  ```bash  
      kubectl get sc
  ```

]

---

## The default StorageClasses

- OpenEBS typically creates three default StorageClasses

- `openebs-jiva-default` provisions 3 replicated Jiva pods per volume

  - data is stored in `/openebs` in the replica pods
  - `/openebs` is a localpath volume mapped to `/var/openebs/pvc-...` on the node

- `openebs-hostpath` uses LocalPV with local directories

  - volumes are hostpath volumes created in `/var/openebs/local` on each node

- `openebs-device` uses LocalPV with local block devices

  - requires available disks and/or a bit of extra configuration
  - the default configuration filters out loop, LVM, MD devices

---

## When do we need custom StorageClasses?

- To store LocalPV hostpath volumes on a different path on the host

- To change the number of replicated Jiva pods

- To use a different Jiva pool

  (i.e. a different path on the host to store the Jiva volumes)

- To create a cStor pool

- ...

---

class: extra-details

## Defining a custom StorageClass

Example for a LocalPV hostpath class using an extra mount on `/mnt/vol001`:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: localpv-hostpath-mntvol001
  annotations:
    openebs.io/cas-type: local
    cas.openebs.io/config: |
      - name: BasePath
        value: "/mnt/vol001"
      - name: StorageType
        value: "hostpath"
provisioner: openebs.io/local
```

- `provisioner` needs to be set accordingly
- Storage engine is chosen by specifying the annotation `openebs.io/cas-type`
- Storage engine configuration is set with the annotation `cas.openebs.io/config` 

---

## Checking the default hostpath StorageClass

- Let's inspect the StorageClass that OpenEBS created for us

.lab[

- Let's look at the OpenEBS LocalPV hostpath StorageClass:
  ```bash
  kubectl get storageclass openebs-hostpath -o yaml
  ``` 
]

---

## Create a host path PVC

- Let's create a Persistent Volume Claim using an explicit StorageClass

.lab[

```bash
kubectl apply -f - <<EOF
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: local-hostpath-pvc
spec:
  storageClassName: openebs-hostpath
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1G
EOF
```

]

---

## Making sure that a PV was created for our PVC

- Normally, the `openebs-hostpath` StorageClass created a PV for our PVC

.lab[

- Look at the PV and PVC:
  ```bash
  kubectl get pv,pvc
  ```

]

---

## Create a Pod to consume the PV

.lab[

- Create a Pod using that PVC:
  ```bash
  kubectl apply -f ~/container.training/k8s/openebs-pod.yaml
  ```

- Here are the sections that declare and use the volume:
  ```yaml
    volumes:
    - name: my-storage
      persistentVolumeClaim:
        claimName: local-hostpath-pvc
    containers:
    ...  
      volumeMounts:
      - mountPath: /mnt/storage
        name: my-storage
  ```

]

---

## Verify that data is written on the node

- Let's find the file written by the Pod on the node where the Pod is running

.lab[

- Get the worker node where the pod is located
  ```bash
  kubectl get pod openebs-local-hostpath-pod -ojsonpath={.spec.nodeName}
  ```

- SSH into the node

- Check the volume content
  ```bash
  sudo tail /var/openebs/local/pvc-*/greet.txt
  ```

]

---

## Heads up!

- The following labs and exercises will use the Jiva storage class

- This storage class creates 3 replicas by default

- It uses *anti-affinity* placement constraits to put these replicas on different nodes

- **This requires a cluster with multiple nodes!**

- It also requires the iSCSI client (aka *initiator*) to be installed on the nodes

- On many platforms, the iSCSI client is preinstalled and will start automatically

- If it doesn't, you might want to check [this documentation page] for details

[this documentation page]: https://docs.openebs.io/docs/next/prerequisites.html

---

## The default StorageClass

- The PVC that we defined earlier specified an explicit StorageClass

- We can also set a default StorageClass

- It will then be used for all PVC that *don't* specify and explicit StorageClass

- This is done with the annotation `storageclass.kubernetes.io/is-default-class`

.lab[

- Check if we have a default StorageClass:
  ```bash
  kubectl get storageclasses
  ```
]

- The default StorageClass (if there is one) is shown with `(default)`

---

## Setting a default StorageClass

- Let's set the default StorageClass to use `openebs-jiva-default`

.lab[

- Remove the annotation (just in case we already have a default class):
  ```bash
  kubectl annotate storageclass storageclass.kubernetes.io/is-default-class- --all
  ```

- Annotate the Jiva StorageClass:
  ```bash
  kubectl annotate storageclasses \
      openebs-jiva-default storageclass.kubernetes.io/is-default-class=true
  ```

- Check the result:
  ```bash
  kuectl get storageclasses
  ```

]

---

## We're ready now!

- We have a StorageClass that can provision PersistentVolumes

- These PersistentVolumes will be replicated across nodes

- They should be able to withstand single-node failures

???

:EN:- Understanding Container Attached Storage (CAS)
:EN:- Deploying stateful apps with OpenEBS

:FR:- Comprendre le "Container Attached Storage" (CAS)
:FR:- Déployer une application "stateful" avec OpenEBS