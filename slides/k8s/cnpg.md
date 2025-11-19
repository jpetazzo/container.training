# CloudNativePG

- CloudNativePG (CNPG) is an operator to run PostreSQL on Kubernetes

- Makes it easy to run production Postgres on K8S

- Supports streaming replication, backups, PITR, TLS, monitoring...

- Open source

- Accepted to CNCF on January 21, 2025 at the Sandbox maturity level

  (https://www.cncf.io/projects/cloudnativepg/)

---

## A few examples

- [EphemeraSearch](https://www.ephemerasearch.com/)

  *personal project, ~200 GB database, tiny budget*

- [Sellsy](https://enix.io/en/clients/)

  *40,000 databases across 50 clusters, Talos, Proxmox VE*

- MistralAI

  *30 production clusters, each from a few GB to a few TB size*

→ CNPG works for environments with small, big, and many clusters!

---

## Typical operation

- Decide what kind of storage we want to use

  (cloud, local, distributed, hyperconverged...)

- Decide on backup strategy

  (typically object store, e.g. S3-compatible)

- Set up `StorageClass` if needed

- Install CNPG

- Deploy Postgres cluster(s) with YAML manifests

- Profit!

---

## Local vs remote storage

- Local storage can feel less safe

  (compared to a SAN, cloud block device, distributed volume...)

- However, it can be much faster

  (much lower latency, much higher throughput)

- If we're using replication, losing a local volume is no problem

- Distributed storage can also fail

  (or be unavailable for a while)

---

## CNPG installation

Example with Helm:
```bash
helm upgrade --install --namespace cnpg-system --create-namespace \
  --repo https://cloudnative-pg.io/charts/ \
  cloudnative-pg cloudnative-pg \
  --version 1.25.1
```

Interesting options to add, to integrate with Prometheus Operator:
```bash
--set monitoring.podMonitorEnabled=true
--set monitoring.grafanaDashboard.create=true
--set monitoring.grafanaDashboard.namespace=prom-system
```

---

## Minimal Postgres cluster

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: minimal
spec:
  instances: 2
  storage:
    size: 10G
```

Note: this is missing (notably) resource requests and backups!

---

## `kubectl` plugin

- There is a `kubectl-cnpg` plugin

- Install it (e.g. with `krew`)

- Check commands like:

  `k cnpg status`

  `k cnpg psql`

  `k cnpg backup`

  `k cnpg promote`

---

## Production clusters

Check the following YAML manifest:

https://github.com/jpetazzo/pozok/blob/main/cluster-production.yaml

If you want to test this, you need an S3-compatible object store.

- Set the required variables:

  `$CLUSTER_NAME`, `$AWS_ACCESS_KEY_ID`, `$AWS_SECRET_ACCESS_KEY`, `$AWS_DEFAULT_REGION`, `$BUCKET_NAME`, `$AWS_ENDPOINT_URL`

- Then `envsubst < cluster-production.yaml | kubectl apply -f-`

- Cluster comes up; backups and WAL segments land in the S3 bucket!

---

## Automated switchover

- CNPG detects when we `kubectl cordon` a node

- It assumes "cordon = maintenance"

- If the node hosts a primary server, it initiates a switchover

- It also uses Pod Disruption Budgets (PDB) to collaborate with evictions

  (the PDB prevents the eviction of the primary until it gets demoted)

---

## Benchmarking

- Postgres has `pgbench`

- Step 1: execute e.g. `pgbench -i -s 10` to prepare the database

  (`-s` is an optional "scaling factor" for a bigger dataset)

- Step 2: execute `pgbench -P1 -T10` to run the benchmark

  (`-P1` = report progress every second, `-T10` = run for 10 seconds)

- These commands can be executed in the pod running the primary, e.g.:

  `kubectl exec minimal-1 -- pgbench app -i -s 10`

  `kubectl exec minimal-1 -- pgbench app -P1 -T60`

---

## CNPG lab 1

- Install CNPG on a managed cluster with a default `StorageClass`

- Provision a CNPG cluster (primary+replica)

- Run a `pgbench` (e.g. 60 seconds)

- Note the number of transactions / second

- Install another `StorageClass` (e.g. `rancher/local-path-provisioner`)

- Provision another CNPG cluster with that storage class

- Run a benchmark and compare the numbers

- Discuss!

---

## CNPG lab 2

- This one requires access to an S3-compatible object store

- Deploy a cluster sending backups to the object store

- Run a benchmark (to populate the database)

- Trigger a backup (e.g. with `k cnpg backup`)

- Create a new cluster from the backup

- Confirm that the numbers of rows (e.g. in `pgbench_history`) is the same

???

:EN:- Deploying Postgres clusters with CloudNativePG
:FR:- Déployer des clusters Postgres avec CloudNativePG
