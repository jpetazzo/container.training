# Backing up clusters

- Backups can have multiple purposes:

  - disaster recovery (servers or storage are destroyed or unreachable)

  - error recovery (human or process has altered or corrupted data)

  - cloning environments (for testing, validation...)

- Let's see the strategies and tools available with Kubernetes!

---

## Important

- Kubernetes helps us with disaster recovery

  (it gives us replication primitives)

- Kubernetes helps us clone / replicate environments

  (all resources can be described with manifests)

- Kubernetes *does not* help us with error recovery

- We still need to back up/snapshot our data:

  - with database backups (mysqldump, pgdump, etc.)

  - and/or snapshots at the storage layer

  - and/or traditional full disk backups

---

## In a perfect world ...

- The deployment of our Kubernetes clusters is automated

  (recreating a cluster takes less than a minute of human time)

- All the resources (Deployments, Services...) on our clusters are under version control

  (never use `kubectl run`; always apply YAML files coming from a repository)

- Stateful components are either:

  - stored on systems with regular snapshots

  - backed up regularly to an external, durable storage

  - outside of Kubernetes

---

## Kubernetes cluster deployment

- If our deployment system isn't fully automated, it should at least be documented

- Litmus test: how long does it take to deploy a cluster...

  - for a senior engineer?

  - for a new hire?

- Does it require external intervention?

  (e.g. provisioning servers, signing TLS certs...)

---

## Plan B

- Full machine backups of the control plane can help

- If the control plane is in pods (or containers), pay attention to storage drivers

  (if the backup mechanism is not container-aware, the backups can take way more resources than they should, or even be unusable!)

- If the previous sentence worries you:

  **automate the deployment of your clusters!**

---

## Managing our Kubernetes resources

- Ideal scenario:

  - never create a resource directly on a cluster

  - push to a code repository

  - a special branch (`production` or even `master`) gets automatically deployed

- Some folks call this "GitOps"

  (it's the logical evolution of configuration management and infrastructure as code)

---

## GitOps in theory

- What do we keep in version control?

- For very simple scenarios: source code, Dockerfiles, scripts

- For real applications: add resources (as YAML files)

- For applications deployed multiple times: Helm, Kustomize...

  (staging and production count as "multiple times")

---

## GitOps tooling

- Various tools exist (Weave Flux, GitKube...)

- These tools are still very young

- You still need to write YAML for all your resources

- There is no tool to:

  - list *all* resources in a namespace

  - get resource YAML in a canonical form

  - diff YAML descriptions with current state

---

## GitOps in practice

- Start describing your resources with YAML

- Leverage a tool like Kustomize or Helm

- Make sure that you can easily deploy to a new namespace

  (or even better: to a new cluster)

- When tooling matures, you will be ready

---

## Plan B

- What if we can't describe everything with YAML?

- What if we manually create resources and forget to commit them to source control?

- What about global resources, that don't live in a namespace?

- How can we be sure that we saved *everything*?

---

## Backing up etcd

- All objects are saved in etcd

- etcd data should be relatively small

  (and therefore, quick and easy to back up)

- Two options to back up etcd:

  - snapshot the data directory

  - use `etcdctl snapshot`

---

## Making an etcd snapshot

- The basic command is simple:
  ```bash
  etcdctl snapshot save <filename>
  ```

- But we also need to specify:

  - the address of the server to back up

  - the path to the key, certificate, and CA certificate
    <br/>(if our etcd uses TLS certificates)

  - an environment variable to specify that we want etcdctl v3
    <br/>(not necessary anymore with recent versions of etcd)

---

## Snapshotting etcd on kubeadm 

- Here is a strategy that works on clusters deployed with kubeadm

  (and maybe others)

- We're going to:

  - identify a node running the control plane

  - identify the etcd image

  - execute `etcdctl snapshot` in a *debug container*

  - transfer the resulting snapshot with another *debug container*

---

## Finding an etcd node and image

These commands let us retrieve the node and image automatically.

.lab[

- Get the name of a control plane node:
  ```bash
  NODE=$(kubectl get nodes \
           --selector=node-role.kubernetes.io/control-plane \
           -o jsonpath={.items[0].metadata.name})
  ```

- Get the etcd image:
  ```bash
  IMAGE=$(kubectl get pods --namespace kube-system etcd-$NODE \
            -o jsonpath={..containers[].image})
  ```

]

---

## Making a snapshot

This relies on the fact that in a `node` debug pod:

- the host filesystem is mounted in `/host`,
- the debug pod is using the host's network.

.lab[

- Execute `etcdctl` in a debug pod:
  ```bash
    kubectl debug --attach --profile=general \
      node/$NODE --image $IMAGE -- \
      etcdctl --endpoints=https://[127.0.0.1]:2379 \
              --cacert=/host/etc/kubernetes/pki/etcd/ca.crt \
              --cert=/host/etc/kubernetes/pki/etcd/healthcheck-client.crt \
              --key=/host/etc/kubernetes/pki/etcd/healthcheck-client.key \
              snapshot save /host/tmp/snapshot
  ```

]

---

## Transfer the snapshot

We're going to use base64 encoding to ensure that the snapshot
doesn't get corrupted in transit.

.lab[

- Retrieve the snapshot:
  ```bash
    kubectl debug --attach --profile=general --quiet \
      node/$NODE --image $IMAGE -- \
      base64 /host/tmp/snapshot | base64 -d > snapshot
  ```

]

We can now work with the `snapshot` file in the current directory!

---

## Restoring an etcd snapshot

- ~~Execute exactly the same command, but replacing `save` with `restore`~~

  (Believe it or not, doing that will *not* do anything useful!)

- The `restore` command does *not* load a snapshot into a running etcd server

- The `restore` command creates a new data directory from the snapshot

  (it's an offline operation; it doesn't interact with an etcd server)

- It will create a new data directory in a temporary container

  (leaving the running etcd node untouched)

---

## When using kubeadm

1. Create a new data directory from the snapshot:
   ```bash
   sudo rm -rf /var/lib/etcd
   docker run --rm -v /var/lib:/var/lib -v $PWD:/vol $IMAGE \
          etcdctl snapshot restore /vol/snapshot --data-dir=/var/lib/etcd
   ```

2. Provision the control plane, using that data directory:
   ```bash
   sudo kubeadm init \
        --ignore-preflight-errors=DirAvailable--var-lib-etcd
   ```

3. Rejoin the other nodes

---

## The fine print

- This only saves etcd state

- It **does not** save persistent volumes and local node data

- Some critical components (like the pod network) might need to be reset

- As a result, our pods might have to be recreated, too

- If we have proper liveness checks, this should happen automatically

---

## Accessing etcd directly

- Data in etcd is encoded in a binary format

- We can retrieve the data with etcdctl, but it's hard to read

- There is a tool to decode that data: `auger`

- Check the [use cases][auger-use-cases] for an example of how to retrieve and modify etcd data!

[auger-use-cases]: https://github.com/etcd-io/auger?tab=readme-ov-file#use-cases

---

## More information about etcd backups

- [Kubernetes documentation](https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/#built-in-snapshot) about etcd backups

- [etcd documentation](https://coreos.com/etcd/docs/latest/op-guide/recovery.html#snapshotting-the-keyspace) about snapshots and restore

- [A good blog post by elastisys](https://elastisys.com/2018/12/10/backup-kubernetes-how-and-why/) explaining how to restore a snapshot

- [Another good blog post by consol labs](https://labs.consol.de/kubernetes/2018/05/25/kubeadm-backup.html) on the same topic

- [auger](https://github.com/etcd-io/auger), a tool to directly access Kubernetes objects stored in etcd

---

## Don't forget ...

- Also back up the TLS information

  (at the very least: CA key and cert; API server key and cert)

- With clusters provisioned by kubeadm, this is in `/etc/kubernetes/pki`

- If you don't:

  - you will still be able to restore etcd state and bring everything back up

  - you will need to redistribute user certificates

.warning[**TLS information is highly sensitive! 
<br/>Anyone who has it has full access to your cluster!**]

---

## Stateful services

- It's totally fine to keep your production databases outside of Kubernetes

  *Especially if you have only one database server!*

- Feel free to put development and staging databases on Kubernetes

  (as long as they don't hold important data)

- Using Kubernetes for stateful services makes sense if you have *many*

  (because then you can leverage Kubernetes automation)

---

## Snapshotting persistent volumes

- Option 1: snapshot volumes out of band

  (with the API/CLI/GUI of our SAN/cloud/...)

- Option 2: storage system integration

  (e.g. [Portworx](https://docs.portworx.com/portworx-install-with-kubernetes/storage-operations/create-snapshots/) can [create snapshots through annotations](https://docs.portworx.com/portworx-install-with-kubernetes/storage-operations/create-snapshots/snaps-annotations/#taking-periodic-snapshots-on-a-running-pod))

- Option 3: [snapshots through Kubernetes API](https://kubernetes.io/docs/concepts/storage/volume-snapshots/)

  (Generally available since Kuberentes 1.20 for a number of [CSI](https://kubernetes.io/blog/2019/01/15/container-storage-interface-ga/) volume plugins : GCE, OpenSDS, Ceph, Portworx, etc)

---

## More backup tools

- [Stash](https://stash.run/)

  back up Kubernetes persistent volumes

- ~~Heptio Ark~~ [Velero](https://velero.io/)

  full cluster backup

- [kube-backup](https://github.com/pieterlange/kube-backup) (unmaintained)

  simple scripts to save resource YAML to a git repository
  
- [bivac](https://github.com/camptocamp/bivac) 

  Backup Interface for Volumes Attached to Containers 

- [Veeam Kasten](https://www.veeam.com/products/cloud/kubernetes-data-protection.html)

  commercial product; compares to Velero

???

:EN:- Backing up clusters
:FR:- Politiques de sauvegarde
