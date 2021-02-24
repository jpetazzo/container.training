# OpenEBS 

 - OpenEBS is a popular open-source storage solution for Kubernetes

 - Think "Container Attached Storage"

 - Supports a wide range of storage engines:
   - Jiva: for lighter workloads with basic cloning/snapshotting

   - cStor: based on iSCSI

   - Mayastor: light-weight abstraction layer with nVME and vhost-user support

   - OpenEBS Local PV - for lowest latency local volumes

---
## Installing OpenEBS with Helm

OpenEBS control plane runs as a set of containers on Kubernetes worker nodes. 
It can be installed with helm:

.exercise[

  - Install OpenEBS
```bash  
    kubectl create ns openebs
    helm repo add openebs https://openebs.github.io/charts
    helm repo update
    helm install openebs openebs/openebs --namespace openebs
```
]

---

## Installing OpenEBS with Helm

Let's check the running OpenEBS components:

.exercise[

```bash  
    kubectl get pod -n openebs
```
]

Let's check the new StorageClasses:

.exercise[

```bash  
    kubectl get sc
```
]

---

## Default Storage Classes 

For a simple testing of OpenEBS, you can use the below default storage classes:

 - **openebs-jiva-default** for provisioning Jiva Volume (this uses default pool which means the data replicas are created in the /mnt/openebs_disk directory of the Jiva replica pod)

 - **openebs-hostpath** for provisioning Local PV on hostpath.

 - **openebs-device** for provisioning Local PV on device.

For using real disks, you have to create *cStorPools* or *Jiva* pools or *OpenEBS Local PV* based on the requirement and then create corresponding StorageClasses or use default StorageClasses to use them.

---

## Selecting an OpenEBS Storage Engine

Storage engine is chosen by specifying the annotation `openebs.io/cas-type` in the StorageClass specification. StorageClass defines the provisioner details. Separate provisioners are specified for each CAS engine.

Example for Local PV host path:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: localpv-hostpath-sc
  annotations:
    openebs.io/cas-type: local
    cas.openebs.io/config: |
      - name: BasePath
        value: "/var/openebs/local"
      - name: StorageType
        value: "hostpath"
provisioner: openebs.io/local
```

---

## Exploring the host path StorageClass

.exercise[
    - Let's look at the OpenEBS Local PV host path StorageClass
    ```bash
    kubectl get sc openebs-hostpath -oyaml
    ``` 
]

---

##  Create a host path PVC

Let's create a Persistent Volume Claim
.exercise[
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

kubectl get pvc
```
]

---
## Create a pod to consume the PV

.exercise[
- Create a pod from yaml:
```
kubectl apply -f ~/container.training/k8s/openebs-pod.yaml
```
- Look at the pod definition:
```
  volumes:
  \- name: my-storage
     persistentVolumeClaim:
       claimName: local-hostpath-pvc
  containers:
....  
    volumeMounts:
    \- mountPath: /mnt/storage
      name: my-storage
```
]

---
### Verify the data is written

.exercise[
 - Get the worker node where the pod is located
 ```
kubectl get pod openebs-local-hostpath-pod -ojsonpath
="{ .spec.nodeName }"
```
- ssh into the node

- check the volume content
```
sudo cat /var/openebs/local/pvc-*/greet.txt
```
]