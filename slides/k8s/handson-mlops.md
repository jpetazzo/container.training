class: title

*Tell me and I forget.*
<br/>
*Teach me and I remember.*
<br/>
*Involve me and I learn.*

Misattributed to Benjamin Franklin

[(Probably inspired by Chinese Confucian philosopher Xunzi)](https://www.barrypopik.com/index.php/new_york_city/entry/tell_me_and_i_forget_teach_me_and_i_may_remember_involve_me_and_i_will_lear/)

---

## Hands-on sections

- There will be *a lot* of examples and demos

- If you are attending a live workshop:

  - follow along with the demos, ask questions at any time

  - if you can, try to run some of the examples and demos in your environment

  - if things are going too fast, ask the trainer to slow down :)

- If you are watching a recording or only reading the slides:

  - it is **strongly** recommended to run **all** the examples and demos

  - take advantage of the fact that you can pause at any time

---

class: in-person

## Where are we going to run our containers?

---

class: in-person, pic

![You get a cluster](images/you-get-a-cluster.jpg)

---

## If you're attending a live training or workshop

- Each person gets a private lab environment

- Your lab environments will be available for the duration of the workshop

  (check with your instructor to know exactly when they'll be shut down)

- Note that for budget reasons¹, your environment will be fairly modest

  - scenario 1: 4 nodes with 2 cores and 4 GB RAM ; no cluster autoscaling

  - scenario 2: 1 node with 4 cores and 8 GB RAM ; cluster autoscaling

.footnote[¹That cloud thing is mighty expensive, yo]

---

## Running your own lab environment

- If you are following a self-paced course...

- Or watching a replay of a recorded course...

- ...You will need to set up a local environment for the labs

  *or*

- If you want to use a specific cloud provider...

- Or want to see these concepts "at scale"...

- ...You can set up your own clusters with whatever capacity suits you

---

## Deploying your own Kubernetes cluster

- You need cloud provider credentials for this

- Option 1: use the cloud provider CLI, web UI, ...

- Option 2: use [one of these Terraform configurations][one-kubernetes]

  (set `cluster_name`, `node_size`, `max_nodes_per_pool`, `location`, and GO!)

[one-kubernetes]: https://github.com/jpetazzo/container.training/tree/main/prepare-labs/terraform/one-kubernetes

---

## Deploying your own Kubernetes cluster.red[**s**]

- If you want to deliver your own training or workshop:

  - deployment scripts are available in the [prepare-labs] directory

  - you can use them to automatically deploy many lab environments

  - they support many different infrastructure providers

  - they can deploy dozens (even hundreds) of clusters at a time

[prepare-labs]: https://github.com/jpetazzo/container.training/tree/main/prepare-labs

---

## Our recommendation

- Any managed Kubernetes cluster

- Nodes with 8 GB of RAM (or more)

- At least 1 node (obviously!)

- Ideally, cluster autoscaling

  (you can set the maximum number of nodes to 5)

- Alternatively, have a cluster of at least 3 nodes

  (ideally a bit more to see the effect of scaling)

- Local tools: kubectl, Helm, Stern, Bento

- You can also use [shpod] to get a shell on the cluster

[shpod]: https://github.com/jpetazzo/shpod

---

## Example with Linode (create cluster)

- Make sure you have a [Linode account][linode-account]

- Install and configure the [Linode CLI][linode-cli]

- Create a cluster:
  ```bash
  lin lke cluster-create --label mlops \
    --k8s_version=1.31 \
    --node_pools.type g6-standard-4 \
    --node_pools.count 1 \
    --node_pools.autoscaler.enabled true \
    --node_pools.autoscaler.min 1 \
    --node_pools.autoscaler.max 5 \
    #
  ```

[linode-account]: https://login.linode.com/signup
[linode-cli]: https://www.linode.com/products/cli/

---

## Example with Linode (retrieve kubeconfig)

- Retrieve the cluster ID:
  ```bash
  CLUSTER_ID=$(lin  lke clusters-list --label $CLUSTER_NAME  --json | jq .[].id)
  ```

- Wait until the cluster is provisioned:
  ```bash
    while ! lin lke kubeconfig-view $CLUSTER_ID; do
      sleep 10
    done
  ```

- Retrieve the cluster kubeconfig:
  ```bash
    lin lke kubeconfig-view $CLUSTER_ID --json | jq -r .[].kubeconfig | 
        base64 -d > kubeconfig.$CLUSTER_ID
  ```

- And set the `KUBECONFIG` environment variable accordingly!

---

class: in-person

## Why don't we run containers locally?

- Installing this stuff can be hard on some machines

  (32 bits CPU or OS... Laptops without administrator access... etc.)

- *"The whole team downloaded all these container images from the WiFi!
  <br/>... and it went great!"* (Literally no-one ever)

- All you need is a computer (or even a phone or tablet!), with:

  - an Internet connection

  - a web browser

  - an SSH client

- Some of the demos require multiple nodes to demonstrate scaling
