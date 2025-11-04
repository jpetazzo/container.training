# K03- Installing OpenEBS as our CSI

`OpenEBS` is a _CSI_ solution capable of hyperconvergence, synchronous replication and other extra features.  
It installs with `Helm` charts.

- `Flux` is able to watch `Helm` repositories and install `HelmReleases`
- To inject its configuration into the `Helm chart` , `Flux` relies on a `ConfigMap` including the `values.yaml` file

.lab[

```bash
k8s@shpod ~$  mkdir -p ./clusters/METAL/openebs/ &&                  \
              cp -pr ~/container.training/k8s/M6-openebs-*.yaml      \
                    ./clusters/METAL/openebs/ &&                     \
              cd ./clusters/METAL/openebs/ &&                        \
              mv M6-openebs-kustomization.yaml kustomization.yaml && \
              cd - 
```

]

---

## Creating an `Helm` source in Flux for OpenEBS Helm chart

.lab[

```bash
k8s@shpod ~$ flux create source helm openebs \
    --url=https://openebs.github.io/openebs  \
    --interval=3m                            \
    --export > ./clusters/METAL/openebs/sync.yaml
```

]

---

## Creating the `HelmRelease` in Flux

.lab[

```bash
k8s@shpod ~$ flux create helmrelease openebs    \
    --namespace=openebs                         \
    --source=HelmRepository/openebs.flux-system \
    --chart=openebs                             \
    --values-from=ConfigMap/openebs-values     \
    --export >> ./clusters/METAL/openebs/sync.yaml
```

]

---

## 📂 Let's review the files

- `M6-openebs-components.yaml`
  </br>To include the `Flux` resources in the same _namespace_ where `Flux` installs the `OpenEBS` resources, we need to create the _namespace_ **before** the installation occurs

- `sync.yaml`
  </br>The resources `Flux` uses to watch and get the `Helm chart`
  
- `M6-openebs-values.yaml`
  </br> the `values.yaml` file that will be injected into the `Helm chart`

- `kustomization.yaml`
  </br>This one is a bit special: it includes a [ConfigMap generator](https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/configmapgenerator/)

- `M6-openebs-kustomizeconfig.yaml`
  </br></br>This one is tricky: in order for `Flux` to trigger an upgrade of the `Helm Release` when the `ConfigMap` is altered, you need to explain to the `Kustomize ConfigMap generator` how the resources are relating with each others. 🤯 
 
And here we go!

---

class: pic

![Running Mario](images/running-mario.gif)

---

## And the result

Now, we have a _cluster_ featuring `openEBS`.  
But still… The PersistentVolumeClaim remains in `Pending` state!😭

```bash
k8s@shpod ~$ kubectl get storageclass
NAME               PROVISIONER        RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
openebs-hostpath   openebs.io/local   Delete          WaitForFirstConsumer   false                  82m
```
We still don't have a default `StorageClass`!😤

---

### Manually enforcing the default `StorageClass`

Even if Flux is constantly reconciling our resources, we still are able to test evolutions by hand.

.lab[

```bash
k8s@shpod ~$ flux suspend helmrelease openebs -n openebs
► suspending helmrelease openebs in openebs namespace
✔ helmrelease suspended
k8s@shpod ~$ kubectl patch storageclass openebs-hostpath \
                -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

k8s@shpod ~$ k get storageclass
NAME                         PROVISIONER        RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
openebs-hostpath (default)   openebs.io/local   Delete          WaitForFirstConsumer   false                  82m
```

]

---

### Now the database is OK

```bash
k8s@shpod ~$ get pvc,pods -n movy-test
NAME                                         STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS       VOLUMEATTRIBUTESCLASS   AGE
persistentvolumeclaim/postgresql-data-db-0   Bound    pvc-ede1634f-2478-42cd-8ee3-7547cd7cdde2   1Gi        RWO            openebs-hostpath   <unset>                 20m

NAME                       READY   STATUS    RESTARTS   AGE
pod/db-0                   1/1     Running   0          5h43m
(…)
```
