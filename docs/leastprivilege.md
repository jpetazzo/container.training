# Least privilege model

- All the important data is stored in the "Raft log"

- Managers nodes have read/write access to this data

- Workers nodes have no access to this data

- Workers only receive the minimum amount of data that they need:

  - which services to run
  - network configuration information for these services
  - credentials for these services

- Compromising a worker node does not give access to the full cluster

---

## What can I do if I compromise a worker node?

- I can enter the containers running on that node

- I can access the configuration and credentials used by these containers

- I can inspect the network traffic of these containers

- I cannot inspect or disrupt the network traffic of other containers

  (network information is provided by manager nodes; ARP spoofing is not possible)

- I cannot infer the topology of the cluster and its number of nodes

- I can only learn the IP addresses of the manager nodes

---

## Guidelines for workload isolation leveraging least privilege model

- Define security levels

- Define security zones

- Put managers in the highest security zone

- Enforce workloads of a given security level to run in a given zone

- Enforcement can be done with [Authorization Plugins](https://docs.docker.com/engine/extend/plugins_authorization/)
