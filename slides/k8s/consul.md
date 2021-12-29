# Running a Consul cluster

- Here is a good use-case for Stateful sets!

- We are going to deploy a Consul cluster with 3 nodes

- Consul is a highly-available key/value store

  (like etcd or Zookeeper)

- One easy way to bootstrap a cluster is to tell each node:

  - the addresses of other nodes

  - how many nodes are expected (to know when quorum is reached)

---

## Bootstrapping a Consul cluster

*After reading the Consul documentation carefully (and/or asking around),
we figure out the minimal command-line to run our Consul cluster.*

```
consul agent -data-dir=/consul/data -client=0.0.0.0 -server -ui \
       -bootstrap-expect=3 \
       -retry-join=`X.X.X.X` \
       -retry-join=`Y.Y.Y.Y`
```

- Replace X.X.X.X and Y.Y.Y.Y with the addresses of other nodes

- A node can add its own address (it will work fine)

- ... Which means that we can use the same command-line on all nodes (convenient!)

---

## Cloud Auto-join

- Since version 1.4.0, Consul can use the Kubernetes API to find its peers

- This is called [Cloud Auto-join]

- Instead of passing an IP address, we need to pass a parameter like this:

  ```
  consul agent -retry-join "provider=k8s label_selector=\"app=consul\""
  ```

- Consul needs to be able to talk to the Kubernetes API

- We can provide a `kubeconfig` file

- If Consul runs in a pod, it will use the *service account* of the pod

[Cloud Auto-join]: https://www.consul.io/docs/agent/cloud-auto-join.html#kubernetes-k8s-

---

## Setting up Cloud auto-join

- We need to create a service account for Consul

- We need to create a role that can `list` and `get` pods

- We need to bind that role to the service account

- And of course, we need to make sure that Consul pods use that service account

---

## Putting it all together

- The file `k8s/consul-1.yaml` defines the required resources

  (service account, role, role binding, service, stateful set)

- Inspired by this [excellent tutorial](https://github.com/kelseyhightower/consul-on-kubernetes) by Kelsey Hightower

  (many features from the original tutorial were removed for simplicity)

---

## Running our Consul cluster

- We'll use the provided YAML file

.lab[

- Create the stateful set and associated service:
  ```bash
  kubectl apply -f ~/container.training/k8s/consul-1.yaml
  ```

- Check the logs as the pods come up one after another:
  ```bash
  stern consul
  ```

<!--
```wait Synced node info```
```key ^C```
-->

- Check the health of the cluster:
  ```bash
  kubectl exec consul-0 -- consul members
  ```

]

---

## Caveats

- The scheduler may place two Consul pods on the same node

  - if that node fails, we lose two Consul pods at the same time
  - this will cause the cluster to fail

- Scaling down the cluster will cause it to fail

  - when a Consul member leaves the cluster, it needs to inform the others
  - otherwise, the last remaining node doesn't have quorum and stops functioning

- This Consul cluster doesn't use real persistence yet

  - data is stored in the containers' ephemeral filesystem
  - if a pod fails, its replacement starts from a blank slate

---

## Improving pod placement

- We need to tell the scheduler:

  *do not put two of these pods on the same node!*

- This is done with an `affinity` section like the following one:
  ```yaml
    affinity:
      podAntiAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchLabels:
                app: consul
            topologyKey: kubernetes.io/hostname
  ```

---

## Using a lifecycle hook

- When a Consul member leaves the cluster, it needs to execute:
  ```bash
  consul leave
  ```

- This is done with a `lifecycle` section like the following one:
  ```yaml
    lifecycle:
      preStop:
        exec:
          command: [ "sh", "-c", "consul leave" ]
  ```

---

## Running a better Consul cluster

- Let's try to add the scheduling constraint and lifecycle hook

- We can do that in the same namespace or another one (as we like)

- If we do that in the same namespace, we will see a rolling update

  (pods will be replaced one by one)

.lab[

- Deploy a better Consul cluster:
  ```bash
  kubectl apply -f ~/container.training/k8s/consul-2.yaml
  ```

]

---

## Still no persistence, though

- We aren't using actual persistence yet

  (no `volumeClaimTemplate`, Persistent Volume, etc.)

- What happens if we lose a pod?

  - a new pod gets rescheduled (with an empty state)

  - the new pod tries to connect to the two others

  - it will be accepted (after 1-2 minutes of instability)

  - and it will retrieve the data from the other pods

---

## Failure modes

- What happens if we lose two pods?

  - manual repair will be required

  - we will need to instruct the remaining one to act solo

  - then rejoin new pods

- What happens if we lose three pods? (aka all of them)

  - we lose all the data (ouch)

???

:EN:- Scheduling pods together or separately
:EN:- Example: deploying a Consul cluster
:FR:- Lancer des pods ensemble ou séparément
:FR:- Example : lancer un cluster Consul
