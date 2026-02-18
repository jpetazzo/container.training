# Introducing CloudNative-PG

- Formerly in this lab, dev teams were in charge of deploying their own PostgreSQL DB
    - a pretty much complicated `StatefulSet` resource to describe
    - concurrency to `PersistentVolume` creation depending on `StorageClass`
    - no security to access the DB
    - no secret management to manage the connection string
    - no backup
    - no HA
    - …

- Better options should be available!

---

## Operators

Operators are small controllers dedicated to automate operations concerning specific resources (Custom Resource Definitions).

They might be considered as small automated admins!

![Operating levels of operators](images/flux/operator-levels.png)

---

## CloudNative-PG features

`CloudNative-PG` is an operator dedicated to manage PostgreSQL databases.

  - deployment
  - clustering, HA and load-balancing
  - secret management
  - users and credentials
  - PersistentVolumes management
  - security and TLS connectivity
  - backup and recovery
  - monitoring

---

## Deploying in Kubernetes

To deploy in Kubernetes, we've seen several strategies and technologies:

- `kubectl` straight command lines (fast provisionning of very simple resources)
- plain YAML files (might deal with complexity, but might be a bunch of text files)
  - relying on GitOps or CD pipelines (better, but what about DRY?)

- `Kustomize` (plain YAML made modular, quite sexy for easy troubleshooting IMHO, but yet, not very packageable)

- `Helm` charts (embed versionning, and some lifecycle management capabilites like upgrade, uninstall…)
  - but not very centralized and values.yaml hydratation is a pain

- but what about auto-update? rolling update of complex stacks?

---

class:pic

![Operating levels of operators](images/flux/artifacthub.png)

---

# Here comes Operator Lifecycle Manager

OLM is an operator… to manage operator deployments

- It is able to look for updates of the managed operator

- upgrade it

- manage its lifecycle and health condition

---

## OLM CRDs and concepts

It relies on some concepts:

- `CatalogSource`, is a repo of metadata informing OLM on list of operators and their dependencies, ready for deployment

- `Subscription`, describes an intention to deploy an operator (with specific version and update strategy)

- `InstallPlan`, describes the set of resources to deploy so that the operator will then be deployed

- `ClusterServiceVersion`, a version of an operator that is deployed onto the k8s cluster

- `OperatorGroup`, a configuration to configure multitenance for the to-be-deployed operator  

- `OperatorCondition`, a CRD to keep OLM aware of the deployed operator status

---

class:pic

![OperatorHub](images/flux/operatorhub.png)

---

### Creating `kustomization` in Flux for OLM stack

.lab[

```bash
k8s@shpod:~/fleet-config-using-flux-XXXXX$ flux create kustomization olm \
    --namespace=flux-system                                              \
    --source=GitRepository/catalog                                       \
    --path="./k8s/flux/olm/"                                             \
    --export >> ./clusters/CLOUDY/install-components/sync-olm.yaml
```

- ⚠️ Don't forget to add this entry into the `kustomization.yaml` file

]

---

class: pic

![Running Mario](images/running-mario.gif)

---

### Results

.lab[

```bash
k8s@shpod:~/$ k get svc,deployment,batch -n olm
NAME                            TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)     AGE
service/operatorhubio-catalog   ClusterIP   10.32.8.251   <none>        50051/TCP   142m
service/packageserver-service   ClusterIP   10.32.14.28   <none>        5443/TCP    142m

NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/catalog-operator   1/1     1            1           143m
deployment.apps/olm-operator       1/1     1            1           143m
deployment.apps/packageserver      2/2     2            2           142m

NAME                                                                        STATUS     COMPLETIONS   DURATION   AGE
job.batch/a18ec254bf47346e05f64cde7402899251b9da3ea15eb3e092264f92fe9f963   Complete   1/1           11s        138m
```

]

---

## Creating `kustomization` in Flux for CNPG stack

.lab[

```bash
k8s@shpod:~/fleet-config-using-flux-XXXXX$ flux create kustomization cnpg \
    --namespace=flux-system                                               \
    --source=GitRepository/catalog                                        \
    --path="./k8s/flux/cloudnative-pg/"                                   \
    --export >> ./clusters/CLOUDY/install-components/sync-cloudnative-pg.yaml
```

- ⚠️ Don't forget to add this entry into the `kustomization.yaml` file

]

---

class: pic

![Running Mario](images/running-mario.gif)

---

### Results 1/2

.lab[

```bash
k8s@shpod:~/$ k get sub,installplan,csv -A
NAMESPACE   NAME                                                  PACKAGE          SOURCE                  CHANNEL
operators   subscription.operators.coreos.com/my-cloudnative-pg   cloudnative-pg   operatorhubio-catalog   stable-v1

NAMESPACE   NAME                                             CSV                      APPROVAL    APPROVED
operators   installplan.operators.coreos.com/install-4fshw   cloudnative-pg.v1.28.1   Automatic   true

NAMESPACE         NAME                                                                 DISPLAY          VERSION   RELEASE   REPLACES                  PHASE
cilium-secrets    clusterserviceversion.operators.coreos.com/cloudnative-pg.v1.28.1    CloudNativePG    1.28.1              cloudnative-pg.v1.28.0    Installing
cnpg              clusterserviceversion.operators.coreos.com/cloudnative-pg.v1.28.1    CloudNativePG    1.28.1              cloudnative-pg.v1.28.0    InstallReady
default           clusterserviceversion.operators.coreos.com/cloudnative-pg.v1.28.1    CloudNativePG    1.28.1              cloudnative-pg.v1.28.0    Installing
flux-system       clusterserviceversion.operators.coreos.com/cloudnative-pg.v1.28.1    CloudNativePG    1.28.1              cloudnative-pg.v1.28.0    InstallReady
(…)
olm               clusterserviceversion.operators.coreos.com/cloudnative-pg.v1.28.1    CloudNativePG    1.28.1              cloudnative-pg.v1.28.0    Installing
olm               clusterserviceversion.operators.coreos.com/packageserver             Package Server   v0.40.0                                       Succeeded
operators         clusterserviceversion.operators.coreos.com/cloudnative-pg.v1.28.1    CloudNativePG    1.28.1              cloudnative-pg.v1.28.0    Installing
```

]

---

### Results 2/2

.lab[

```bash
k8s@shpod:~/$ k get crds | grep cnpg.io
backups.postgresql.cnpg.io                       2026-02-18T16:20:43Z
clusterimagecatalogs.postgresql.cnpg.io          2026-02-18T16:20:43Z
clusters.postgresql.cnpg.io                      2026-02-18T16:20:44Z
databases.postgresql.cnpg.io                     2026-02-18T16:20:45Z
failoverquorums.postgresql.cnpg.io               2026-02-18T16:20:45Z
imagecatalogs.postgresql.cnpg.io                 2026-02-18T16:20:45Z
poolers.postgresql.cnpg.io                       2026-02-18T16:20:46Z
publications.postgresql.cnpg.io                  2026-02-18T16:20:46Z
scheduledbackups.postgresql.cnpg.io              2026-02-18T16:20:47Z
subscriptions.postgresql.cnpg.io                 2026-02-18T16:20:47Z
```

]

---

## Upgrading **_🎬MOVY_** app

**_🎬MOVY_** team can now rely on an enterprise-grade DB.

- Copy file `./k8s/plain/cluster.yaml` from the main branch into the `movy` branch of their repository

- In `./k8s/plain/deployment-web.yaml` file, replace the `SPRING_DATASOURCE_URL` object by the following…

```yaml
- name: SPRING_DATASOURCE_URL
  valueFrom:
      secretKeyRef:
          name: db-app
          key: fqdn-jdbc-uri
```

CloudNative-PG creates a bunch of secrets for a pod to be able to connect to the PostGreSQL cluster!

---

class: pic

![Running Mario](images/running-mario.gif)

---

### Results 1/2

- A new cluster and credentials to connect to it have been created.  
- And its scheduled backup too !

.lab[

```bash
k8s@shpod:~/$ k get cluster,scheduledbackup,secret
NAME                            AGE     INSTANCES   READY   STATUS                     PRIMARY
cluster.postgresql.cnpg.io/db   3m39s   2           2       Cluster in healthy state   db-1

NAME                                           AGE     CLUSTER   LAST BACKUP
scheduledbackup.postgresql.cnpg.io/backup-db   3m38s   db        20s

NAME                    TYPE                       DATA   AGE
secret/db-app           kubernetes.io/basic-auth   11     3m38s
secret/db-ca            Opaque                     2      3m38s
secret/db-replication   kubernetes.io/tls          2      3m38s
secret/db-server        kubernetes.io/tls          2      3m38s
```

]

---

### Results 2/2

.lab[

```bash
k8s@shpod:~/$ k get cluster,scheduledbackup,secret
k get pods,svc,pv,pvc
NAME       READY   STATUS    RESTARTS   AGE
pod/db-1   1/1     Running   0          3m30s
pod/db-2   1/1     Running   0          2m24s

NAME                 TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
service/db-r         ClusterIP   10.32.11.189   <none>        5432/TCP   5m1s
service/db-ro        ClusterIP   10.32.8.17     <none>        5432/TCP   5m1s
service/db-rw        ClusterIP   10.32.13.208   <none>        5432/TCP   5m1s
service/kubernetes   ClusterIP   10.32.0.1      <none>        443/TCP    3h1m

NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                              STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
persistentvolume/pvc-17d4f3c6-767e-4cd7-a60d-14cf61825739   1Gi        RWO            Delete           Bound    default/db-2                       sbs-default    <unset>                          3m2s
persistentvolume/pvc-4276cefd-9e0b-4ad1-bee5-2dcb1bdbbb7c   1Gi        RWO            Delete           Bound    default/db-1                       sbs-default    <unset>                          4m55s

NAME                         STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
persistentvolumeclaim/db-1   Bound    pvc-4276cefd-9e0b-4ad1-bee5-2dcb1bdbbb7c   1Gi        RWO            sbs-default    <unset>                 5m1s
persistentvolumeclaim/db-2   Bound    pvc-17d4f3c6-767e-4cd7-a60d-14cf61825739   1Gi        RWO            sbs-default    <unset>                 3m7s
```

]
