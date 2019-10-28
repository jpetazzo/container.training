class: title

Building a 1-node cluster

---

## Requirements

- Linux machine (x86_64)

  2 GB RAM, 1 CPU is OK

- Root (for Docker and Kubelet)

- Binaries:

  - etcd

  - Kubernetes

  - Docker

---

## What we will do

- Create a deployment

  (with `kubectl create deployment`)


- Look for our pods

- If pods are created: victory

- Else: troubleshoot, try again

.footnote[*Note: the exact commands that I run will be available
in the slides of the tutorial.*]

---

class: pic

![Demo time!](images/demo-with-kht.png)

---

## What have we done?

- Started a basic Kubernetes control plane

  (no authentication; many features are missing)

- Deployed a few pods

