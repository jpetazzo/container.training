# Adding nodes to the cluster

- So far, our cluster has only 1 node

- Let's see what it takes to add more nodes

- We are going to use another set of machines: `kubenet`

---

## The environment

- We have 3 identical machines: `kubenet1`, `kubenet2`, `kubenet3`

- The Docker Engine is installed (and running) on these machines

- The Kubernetes packages are installed, but nothing is running

- We will use `kubenet1` to run the control plane

---

## The plan

- Start the control plane on `kubenet1`

- Join the 3 nodes to the cluster

- Deploy and scale a simple web server

.exercise[

- Log into `kubenet1`

]

---

## Running the control plane

- We will use a Compose file to start the control plane components

.exercise[

- Clone the repository containing the workshop materials:
  ```bash
  git clone https://@@GITREPO@@
  ```

- Go to the `compose/simple-k8s-control-plane` directory:
  ```bash
  cd container.training/compose/simple-k8s-control-plane
  ```

- Start the control plane:
  ```bash
  docker-compose up
  ```

]

---

## Checking the control plane status

- Before moving on, verify that the control plane works

.exercise[

- Show control plane component statuses:
  ```bash
  kubectl get componentstatuses
  kubectl get cs
  ```

- Show the (empty) list of nodes:
  ```bash
  kubectl get nodes
  ```

]

---

class: extra-details

## Differences from `dmuc`

- Our new control plane listens on `0.0.0.0` instead of the default `127.0.0.1`

- The ServiceAccount admission plugin is disabled

---

## Joining the nodes

- We need to generate a `kubeconfig` file for kubelet

- This time, we need to put the public IP address of `kubenet1`

  (instead of `localhost` or `127.0.0.1`)

.exercise[

- Generate the `kubeconfig` file:
  ```bash
    kubectl config set-cluster kubenet --server http://`X.X.X.X`:8080
    kubectl config set-context kubenet --cluster kubenet
    kubectl config use-context kubenet
    cp ~/.kube/config ~/kubeconfig
  ```

]

---

## Distributing the `kubeconfig` file

- We need that `kubeconfig` file on the other nodes, too

.exercise[

- Copy `kubeconfig` to the other nodes:
  ```bash
    for N in 2 3; do
    	scp ~/kubeconfig kubenet$N:
    done
  ```

]

---

## Starting kubelet

- Reminder: kubelet needs to run as root; don't forget `sudo`!

.exercise[

- Join the first node:
   ```bash
   sudo kubelet --kubeconfig ~/kubeconfig
   ```

- Open more terminals and join the other nodes to the cluster:
  ```bash
  ssh kubenet2 sudo kubelet --kubeconfig ~/kubeconfig
  ssh kubenet3 sudo kubelet --kubeconfig ~/kubeconfig
  ```

]

---

## Checking cluster status

- We should now see all 3 nodes

- At first, their `STATUS` will be `NotReady`

- They will move to `Ready` state after approximately 10 seconds

.exercise[

- Check the list of nodes:
  ```bash
  kubectl get nodes
  ```

]

---

## Deploy a web server

- Let's create a Deployment and scale it

  (so that we have multiple pods on multiple nodes)

.exercise[

- Create a Deployment running NGINX:
  ```bash
  kubectl create deployment web --image=nginx
  ```

- Scale it:
  ```bash
  kubectl scale deployment web --replicas=5
  ```

]

---

## Check our pods

- The pods will be scheduled on the nodes

- The nodes will pull the `nginx` image, and start the pods

- What are the IP addresses of our pods?

.exercise[

- Check the IP addresses of our pods
  ```bash
  kubectl get pods -o wide
  ```

]

--

🤔 Something's not right ... Some pods have the same IP address!

---

## What's going on?

- Without the `--network-plugin` flag, kubelet defaults to "no-op" networking

- It lets the container engine use a default network

  (in that case, we end up with the default Docker bridge)

- Our pods are running on independent, disconnected, host-local networks

---

## What do we need to do?

- On a normal cluster, kubelet is configured to set up pod networking with CNI plugins

- This requires:

  - installing CNI plugins

  - writing CNI configuration files

  - running kubelet with `--network-plugin=cni`

---

## Using network plugins

- We need to set up a better network

- Before diving into CNI, we will use the `kubenet` plugin

- This plugin creates a `cbr0` bridge and connects the containers to that bridge

- This plugin allocates IP addresses from a range:

  - either specified to kubelet (e.g. with `--pod-cidr`)

  - or stored in the node's `spec.podCIDR` field

.footnote[See [here] for more details about this `kubenet` plugin.]

[here]: https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/#kubenet

---

## What `kubenet` does and *does not* do

- It allocates IP addresses to pods *locally*

  (each node has its own local subnet)

- It connects the pods to a *local* bridge

  (pods on the same node can communicate together; not with other nodes)

- It doesn't set up routing or tunneling

  (we get pods on separated networks; we need to connect them somehow)

- It doesn't allocate subnets to nodes

  (this can be done manually, or by the controller manager) 

---

## Setting up routing or tunneling

- *On each node*, we will add routes to the other nodes' pod network

- Of course, this is not convenient or scalable!

- We will see better techniques to do this; but for now, hang on!

---

## Allocating subnets to nodes

- There are multiple options:

  - passing the subnet to kubelet with the `--pod-cidr` flag

  - manually setting `spec.podCIDR` on each node

  - allocating node CIDRs automatically with the controller manager

- The last option would be implemented by adding these flags to controller manager:
  ```
  --allocate-node-cidrs=true --cluster-cidr=<cidr> 
  ```

---

class: extra-details

## The pod CIDR field is not mandatory

- `kubenet` needs the pod CIDR, but other plugins don't need it

  (e.g. because they allocate addresses in multiple pools, or a single big one)

- The pod CIDR field may eventually be deprecated and replaced by an annotation

  (see [kubernetes/kubernetes#57130](https://github.com/kubernetes/kubernetes/issues/57130))

---

## Restarting kubelet wih pod CIDR

- We need to stop and restart all our kubelets

- We will add the `--network-plugin` and `--pod-cidr` flags

- We all have a "cluster number" (let's call that `C`) printed on your VM info card

- We will use pod CIDR `10.C.N.0/24` (where `N` is the node number: 1, 2, 3)

.exercise[

- Stop all the kubelets (Ctrl-C is fine)

- Restart them all, adding `--network-plugin=kubenet --pod-cidr 10.C.N.0/24`

]

---

## What happens to our pods?

- When we stop (or kill) kubelet, the containers keep running

- When kubelet starts again, it detects the containers

.exercise[

- Check that our pods are still here:
  ```bash
  kubectl get pods -o wide
  ```

]

🤔 But our pods still use local IP addresses!

---

## Recreating the pods

- The IP address of a pod cannot change

- kubelet doesn't automatically kill/restart containers with "invalid" addresses
  <br/>
  (in fact, from kubelet's point of view, there is no such thing as an "invalid" address)

- We must delete our pods and recreate them

.exercise[

- Delete all the pods, and let the ReplicaSet recreate them:
  ```bash
  kubectl delete pods --all
  ```

- Wait for the pods to be up again:
  ```bash
  kubectl get pods -o wide -w
  ```

]

---

## Adding kube-proxy

- Let's start kube-proxy to provide internal load balancing

- Then see if we can create a Service and use it to contact our pods

.exercise[

- Start kube-proxy:
  ```bash
  sudo kube-proxy --kubeconfig ~/.kube/config
  ```

- Expose our Deployment:
  ```bash
  kubectl expose deployment web --port=80
  ```

]

---

## Test internal load balancing

.exercise[

- Retrieve the ClusterIP address:
  ```bash
  kubectl get svc web
  ```

- Send a few requests to the ClusterIP address (with `curl`)

]

--

Sometimes it works, sometimes it doesn't. Why?

---

## Routing traffic

- Our pods have new, distinct IP addresses

- But they are on host-local, isolated networks

- If we try to ping a pod on a different node, it won't work

- kube-proxy merely rewrites the destination IP address

- But we need that IP address to be reachable in the first place

- How do we fix this?

  (hint: check the title of this slide!)

---

## Important warning

- The technique that we are about to use doesn't work everywhere

- It only works if:

  - all the nodes are directly connected to each other (at layer 2)

  - the underlying network allows the IP addresses of our pods

- If we are on physical machines connected by a switch: OK

- If we are on virtual machines in a public cloud: NOT OK

  - on AWS, we need to disable "source and destination checks" on our instances

  - on OpenStack, we need to disable "port security" on our network ports

---

## Routing basics

- We need to tell *each* node:

  "The subnet 10.C.N.0/24 is located on node N" (for all values of N)

- This is how we add a route on Linux:
  ```bash
  ip route add 10.C.N.0/24 via W.X.Y.Z
  ```

  (where `W.X.Y.Z` is the internal IP address of node N)

- We can see the internal IP addresses of our nodes with:
  ```bash
  kubectl get nodes -o wide
  ```

---

## Firewalling

- By default, Docker prevents containers from using arbitrary IP addresses

  (by setting up iptables rules)

- We need to allow our containers to use our pod CIDR

- For simplicity, we will insert a blanket iptables rule allowing all traffic:

  `iptables -I FORWARD -j ACCEPT`

- This has to be done on every node

---

## Setting up routing

.exercise[

- Create all the routes on all the nodes

- Insert the iptables rule allowing traffic

- Check that you can ping all the pods from one of the nodes

- Check that you can `curl` the ClusterIP of the Service successfully

]

---

## What's next?

- We did a lot of manual operations:

  - allocating subnets to nodes

  - adding command-line flags to kubelet

  - updating the routing tables on our nodes

- We want to automate all these steps

- We want something that works on all networks

???

:EN:- Connecting nodes ands pods
:FR:- Interconnecter les nœuds et les pods
