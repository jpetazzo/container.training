# Building our own cluster

- Let's build our own cluster!

  *Perfection is attained not when there is nothing left to add, but when there is nothing left to take away. (Antoine de Saint-Exupery)*

- Our goal is to build a minimal cluster allowing us to:

  - create a Deployment (with `kubectl create deployment`)
  - expose it with a Service
  - connect to that service


- "Minimal" here means:

  - smaller number of components
  - smaller number of command-line flags
  - smaller number of configuration files

---

## Non-goals

- For now, we don't care about security

- For now, we don't care about scalability

- For now, we don't care about high availability

- All we care about is *simplicity*

---

## Our environment

- We will use the machine indicated as `dmuc1`

  (this stands for "Dessine Moi Un Cluster" or "Draw Me A Sheep",
  <br/>in homage to Saint-Exupery's "The Little Prince")

- This machine:

  - runs Ubuntu LTS

  - has Kubernetes, Docker, and etcd binaries installed

  - but nothing is running

---

## Checking our environment

- Let's make sure we have everything we need first

.exercise[

- Log into the `dmuc1` machine

- Get root:
  ```bash
  sudo -i
  ```

- Check available versions:
  ```bash
  etcd -version
  kube-apiserver --version
  dockerd --version
  ```

]

---

## The plan

1. Start API server

2. Interact with it (create Deployment and Service)

3. See what's broken

4. Fix it and go back to step 2 until it works!

---

## Dealing with multiple processes

- We are going to start many processes

- Depending on what you're comfortable with, you can:

  - open multiple windows and multiple SSH connections

  - use a terminal multiplexer like screen or tmux

  - put processes in the background with `&`
    <br/>(warning: log output might get confusing to read!)

---

## Starting API server

.exercise[

- Try to start the API server:
  ```bash
  kube-apiserver
  # It will fail with "--etcd-servers must be specified"
  ```

]

Since the API server stores everything in etcd,
it cannot start without it.

---

## Starting etcd

.exercise[

- Try to start etcd:
  ```bash
  etcd
  ```

]

Success!

Note the last line of output:
```
serving insecure client requests on 127.0.0.1:2379, this is strongly discouraged!
```

*Sure, that's discouraged. But thanks for telling us the address!*

---

## Starting API server (for real)

- Try again, passing the `--etcd-servers` argument

- That argument should be a comma-separated list of URLs

.exercise[

- Start API server:
  ```bash
  kube-apiserver --etcd-servers http://127.0.0.1:2379
  ```

]

Success!

---

## Interacting with API server

- Let's try a few "classic" commands

.exercise[

- List nodes:
  ```bash
  kubectl get nodes
  ```

- List services:
  ```bash
  kubectl get services
  ```

]

We should get `No resources found.` and the `kubernetes` service, respectively.

Note: the API server automatically created the `kubernetes` service entry.

---

class: extra-details

## What about `kubeconfig`?

- We didn't need to create a `kubeconfig` file

- By default, the API server is listening on `localhost:8080`

  (without requiring authentication)

- By default, `kubectl` connects to `localhost:8080`

  (without providing authentication)

---

## Creating a Deployment

- Let's run a web server!

.exercise[

- Create a Deployment with NGINX:
  ```bash
  kubectl create deployment web --image=nginx
  ```

]

Success?

---

## Checking our Deployment status

.exercise[

- Look at pods, deployments, etc.:
  ```bash
  kubectl get all
  ```

]

Our Deployment is in bad shape:
```
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/web   0/1     0            0           2m26s
```

And, there is no ReplicaSet, and no Pod.

---

## What's going on?

- We stored the definition of our Deployment in etcd

  (through the API server)

- But there is no *controller* to do the rest of the work

- We need to start the *controller manager*

---

## Starting the controller manager

.exercise[

- Try to start the controller manager:
  ```bash
  kube-controller-manager
  ```

]

The final error message is:
```
invalid configuration: no configuration has been provided
```

But the logs include another useful piece of information:
```
Neither --kubeconfig nor --master was specified.
Using the inClusterConfig.  This might not work.
```

---

## Reminder: everyone talks to API server

- The controller manager needs to connect to the API server

- It *does not* have a convenient `localhost:8080` default

- We can pass the connection information in two ways:

  - `--master` and a host:port combination (easy)

  - `--kubeconfig` and a `kubeconfig` file

- For simplicity, we'll use the first option

---

## Starting the controller manager (for real)

.exercise[

- Start the controller manager:
  ```bash
  kube-controller-manager --master http://localhost:8080
  ```

]

Success!

---

## Checking our Deployment status

.exercise[

- Check all our resources again:
  ```bash
  kubectl get all
  ```

]

We now have a ReplicaSet.

But we still don't have a Pod.

---

## What's going on?

In the controller manager logs, we should see something like this:
```
E0404 15:46:25.753376   22847 replica_set.go:450] Sync "default/web-5bc9bd5b8d"
failed with `No API token found for service account "default"`, retry after the
token is automatically created and added to the service account
```

- The service account `default` was automatically added to our Deployment

  (and to its pods)

- The service account `default` exists

- But it doesn't have an associated token

  (the token is a secret; creating it requires signature; therefore a CA)

---

## Solving the missing token issue

There are many ways to solve that issue.

We are going to list a few (to get an idea of what's happening behind the scenes).

Of course, we don't need to perform *all* the solutions mentioned here.

---

## Option 1: disable service accounts

- Restart the API server with
  `--disable-admission-plugins=ServiceAccount`

- The API server will no longer add a service account automatically

- Our pods will be created without a service account

---

## Option 2: do not mount the (missing) token

- Add `automountServiceAccountToken: false` to the Deployment spec

  *or*

- Add `automountServiceAccountToken: false` to the default ServiceAccount

- The ReplicaSet controller will no longer create pods referencing the (missing) token

.exercise[

- Programmatically change the `default` ServiceAccount:
  ```bash
  kubectl patch sa default -p "automountServiceAccountToken: false"
  ```

]

---

## Option 3: set up service accounts properly

- This is the most complex option!

- Generate a key pair

- Pass the private key to the controller manager

  (to generate and sign tokens)

- Pass the public key to the API server

  (to verify these tokens)

---

## Continuing without service account token

- Once we patch the default service account, the ReplicaSet can create a Pod

.exercise[

- Check that we now have a pod:
  ```bash
  kubectl get all
  ```

]

Note: we might have to wait a bit for the ReplicaSet controller to retry.

If we're impatient, we can restart the controller manager.

---

## What's next?

- Our pod exists, but it is in `Pending` state

- Remember, we don't have a node so far

  (`kubectl get nodes` shows an empty list)

- We need to:

  - start a container engine

  - start kubelet

---

## Starting a container engine

- We're going to use Docker (because it's the default option)

.exercise[

- Start the Docker Engine:
  ```bash
  dockerd
  ```

]

Success!

Feel free to check that it actually works with e.g.:
```bash
docker run alpine echo hello world
```

---

## Starting kubelet

- If we start kubelet without arguments, it *will* start

- But it will not join the cluster!

- It will start in *standalone* mode

- Just like with the controller manager, we need to tell kubelet where the API server is

- Alas, kubelet doesn't have a simple `--master` option

- We have to use `--kubeconfig`

- We need to write a `kubeconfig` file for kubelet

---

## Writing a kubeconfig file

- We can copy/paste a bunch of YAML

- Or we can generate the file with `kubectl`

.exercise[

- Create the file `~/.kube/config` with `kubectl`:
  ```bash
    kubectl config \
            set-cluster localhost --server http://localhost:8080
    kubectl config \
            set-context localhost --cluster localhost
    kubectl config \
            use-context localhost
  ```

]

---

## Our `~/.kube/config` file

The file that we generated looks like the one below.

That one has been slightly simplified (removing extraneous fields), but it is still valid.

```yaml
apiVersion: v1
kind: Config
current-context: localhost
contexts:
- name: localhost
  context:
    cluster: localhost
clusters:
- name: localhost
  cluster:
    server: http://localhost:8080
```

---

## Starting kubelet

.exercise[

- Start kubelet with that kubeconfig file:
  ```bash
  kubelet --kubeconfig ~/.kube/config
  ```

]

Success!

---

## Looking at our 1-node cluster

- Let's check that our node registered correctly

.exercise[

- List the nodes in our cluster:
  ```bash
  kubectl get nodes
  ```

]

Our node should show up.

Its name will be its hostname (it should be `dmuc1`).

---

## Are we there yet?

- Let's check if our pod is running

.exercise[

- List all resources:
  ```bash
  kubectl get all
  ```

]

--

Our pod is still `Pending`. 🤔

--

Which is normal: it needs to be *scheduled*.

(i.e., something needs to decide which node it should go on.)

---

## Scheduling our pod

- Why do we need a scheduling decision, since we have only one node?

- The node might be full, unavailable; the pod might have constraints ...

- The easiest way to schedule our pod is to start the scheduler

  (we could also schedule it manually)

---

## Starting the scheduler

- The scheduler also needs to know how to connect to the API server

- Just like for controller manager, we can use `--kubeconfig` or `--master`

.exercise[

- Start the scheduler:
  ```bash
  kube-scheduler --master http://localhost:8080
  ```

]

- Our pod should now start correctly

---

## Checking the status of our pod

- Our pod will go through a short `ContainerCreating` phase

- Then it will be `Running`

.exercise[

- Check pod status:
  ```bash
  kubectl get pods
  ```

]

Success!

---

class: extra-details

## Scheduling a pod manually

- We can schedule a pod in `Pending` state by creating a Binding, e.g.:
  ```bash
    kubectl create -f- <<EOF
    apiVersion: v1
    kind: Binding
    metadata:
      name: name-of-the-pod
    target:
      apiVersion: v1
      kind: Node
      name: name-of-the-node
    EOF
  ```

- This is actually how the scheduler works!

- It watches pods, makes scheduling decisions, and creates Binding objects

---

## Connecting to our pod

- Let's check that our pod correctly runs NGINX

.exercise[

- Check our pod's IP address:
  ```bash
  kubectl get pods -o wide
  ```

- Send some HTTP request to the pod:
  ```bash
  curl `X.X.X.X`
  ```

]

We should see the `Welcome to nginx!` page.

---

## Exposing our Deployment

- We can now create a Service associated with this Deployment

.exercise[

- Expose the Deployment's port 80:
  ```bash
  kubectl expose deployment web --port=80
  ```

- Check the Service's ClusterIP, and try connecting:
  ```bash
  kubectl get service web
  curl http://`X.X.X.X`
  ```

]

--

This won't work. We need kube-proxy to enable internal communication.

---

## Starting kube-proxy

- kube-proxy also needs to connect to the API server

- It can work with the `--master` flag

  (although that will be deprecated in the future)

.exercise[

- Start kube-proxy:
  ```bash
  kube-proxy --master http://localhost:8080
  ```

]

---

## Connecting to our Service

- Now that kube-proxy is running, we should be able to connect

.exercise[

- Check the Service's ClusterIP again, and retry connecting:
  ```bash
  kubectl get service web
  curl http://`X.X.X.X`
  ```

]

Success!

---

class: extra-details

## How kube-proxy works

- kube-proxy watches Service resources

- When a Service is created or updated, kube-proxy creates iptables rules

.exercise[

- Check out the `OUTPUT` chain in the `nat` table:
  ```bash
  iptables -t nat -L OUTPUT
  ```

- Traffic is sent to `KUBE-SERVICES`; check that too:
  ```bash
  iptables -t nat -L KUBE-SERVICES
  ```

]

For each Service, there is an entry in that chain.

---

class: extra-details

## Diving into iptables

- The last command showed a chain named `KUBE-SVC-...` corresponding to our service

.exercise[

- Check that `KUBE-SVC-...` chain:
  ```bash
  iptables -t nat -L `KUBE-SVC-...`
  ```

- It should show a jump to a `KUBE-SEP-...` chains; check it out too:
  ```bash
  iptables -t nat -L `KUBE-SEP-...`
  ```

]

This is a `DNAT` rule to rewrite the destination address of the connection to our pod.

This is how kube-proxy works!

---

class: extra-details

## kube-router, IPVS

- With recent versions of Kubernetes, it is possible to tell kube-proxy to use IPVS

- IPVS is a more powerful load balancing framework

  (remember: iptables was primarily designed for firewalling, not load balancing!)

- It is also possible to replace kube-proxy with kube-router

- kube-router uses IPVS by default

- kube-router can also perform other functions

  (e.g., we can use it as a CNI plugin to provide pod connectivity)

---

class: extra-details

## What about the `kubernetes` service?

- If we try to connect, it won't work

  (by default, it should be `10.0.0.1`)

- If we look at the Endpoints for this service, we will see one endpoint:

  `host-address:6443`

- By default, the API server expects to be running directly on the nodes

  (it could be as a bare process, or in a container/pod using the host network)

- ... And it expects to be listening on port 6443 with TLS

???

:EN:- Building our own cluster from scratch
:FR:- Construire son cluster à la main
