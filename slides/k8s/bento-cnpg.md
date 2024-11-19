# Bento & PostgreSQL

- Bento can also use SQL databases for input/output

- We're going to demonstrate that by writing to a PostgreSQL database

- That database will be deployed with the Cloud Native PostGres operator

  (https://cloudnative-pg.io/)

---

## CNPG in a nutshell

- Free, open source

- Originally created by [EDB] (EnterpriseDB, well-known PgSQL experts)

- Non-exhaustive list of features:

  - provisioning of Postgres servers, replicas, bouncers

  - automatic failover

  - backups (full backups and WAL shipping)

  - provisioning from scratch, from backups, PITR

  - manual and automated switchover (e.g. for node maintenance)

  - and many more!

[EDB]: https://www.enterprisedb.com/workload/kubernetes

---

## What we're going to do

1. Install CNPG.

2. Provision a Postgres cluster.

3. Configure Bento to write to that cluster.

4. Set up a Grafana dashboard to see the data.

---

## 1️⃣ Installing CNPG

Many options available, see the [documentation][cnpg-install]:

- raw YAML manifests

- kubectl CNPG plugin (`kubectl cnpg install generate`)

- Helm chart

- OLM

[cnpg-install]: https://cloudnative-pg.io/documentation/1.24/installation_upgrade/

---

## 2️⃣ Provisioning a Postgres cluster

Minimal manifest:

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: db
spec:
  storage:
    size: 1Gi
```

---

class: extra-details

## For production...

We might also add:

- `spec.monitoring.enablePodMonitor: true`

- `spec.instances: 2`

- `resources.{requests,limits}.{cpu,memory}`

- `walStorage.size`

- `backup`

- `postgresql.parameters`

See [this manifest][cluster-maximal] for a detailed example.

[cluster-maximal]: https://github.com/jpetazzo/pozok/blob/main/cluster-maximal.yaml

---

## 3️⃣ Configuring Bento to write to SQL

- We'll use the [`sql_insert`][sql-insert] output

- If our cluster is named `mydb`, there will be a Secret `mydb-app`

- This Secret will contain a `uri` field

- That field can be used as the `dns` in the Bento configuration

- We will also need to create the table that we want to use

  (see next slide for instructions)

[sql-insert]: https://warpstreamlabs.github.io/bento/docs/components/outputs/sql_insert

---

## Creating a table

- If we just want to store the city name and its population:
  ```sql
      CREATE TABLE IF NOT EXISTS cities (
        city varchar(100) NOT NULL,
        population integer
      );
  ```

- This statement can be executed:

  - manually, by getting a `psql` shell with `kubectl cnpg psql mydb app`

  - automatically, with Bento's `init_statatement`

---

## 4️⃣ Viewing the table in Grafana

- In Grafana, in the home menu on the lift, click "connections"

- Add a PostgreSQL data source

- Enter the host:port, database, user, password

- Then add a visualization using that data source

  (it should be relatively self-explanatory!)

---

class: extra-details

## Automating it all

- Expose PostgreSQL credentials through environment variables

  (in the Bento container)

- Use the `${...}` syntax in Bento to use these environment variables

- Export the Grafana dashboard to a JSON file

- Store the JSON file in a ConfigMap, with label `grafana_dashboard=1`

- Create that ConfigMap in the namespace where Grafana is running

- Similarly, data sources (like the Redis and the PostgreSQL one) can be defined in YAML

- And that YAML can be put in a ConfigMap with label `grafana_datasource=1`
