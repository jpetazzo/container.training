# Exposing HTTP services with Ingress resources

- *Services* give us a way to access a pod or a set of pods

- Services can be exposed to the outside world:

  - with type `NodePort` (on a port >30000)

  - with type `LoadBalancer` (allocating an external load balancer)

- What about HTTP services?

  - how can we expose `webui`, `rng`, `hasher`?

  - the Kubernetes dashboard?

  - a new version of `webui`?

---

## Exposing HTTP services

- If we use `NodePort` services, clients have to specify port numbers

  (i.e. http://xxxxx:31234 instead of just http://xxxxx)

- `LoadBalancer` services are nice, but:

  - they are not available in all environments

  - they often carry an additional cost (e.g. they provision an ELB)

  - they require one extra step for DNS integration
    <br/>
    (waiting for the `LoadBalancer` to be provisioned; then adding it to DNS)

- We could build our own reverse proxy

---

## Building a custom reverse proxy

- There are many options available:

  Apache, HAProxy, Hipache, NGINX, Traefik, ...

  (look at [jpetazzo/aiguillage](https://github.com/jpetazzo/aiguillage) for a minimal reverse proxy configuration using NGINX)

- Most of these options require us to update/edit configuration files after each change

- Some of them can pick up virtual hosts and backends from a configuration store

- Wouldn't it be nice if this configuration could be managed with the Kubernetes API?

--

- Enter.red[¹] *Ingress* resources!

.footnote[.red[¹] Pun maybe intended.]

---

## Ingress resources

- Kubernetes API resource (`kubectl get ingress`/`ingresses`/`ing`)

- Designed to expose HTTP services

- Basic features:

  - load balancing
  - SSL termination
  - name-based virtual hosting

- Can also route to different services depending on:

  - URI path (e.g. `/api`→`api-service`, `/static`→`assets-service`)
  - Client headers, including cookies (for A/B testing, canary deployment...)
  - and more!

---

## Principle of operation

- Step 1: deploy an *ingress controller*

  - ingress controller = load balancer + control loop

  - the control loop watches over ingress resources, and configures the LB accordingly

- Step 2: set up DNS

  - associate DNS entries with the load balancer address

- Step 3: create *ingress resources*

  - the ingress controller picks up these resources and configures the LB

- Step 4: profit!

---

## Ingress in action

- We will deploy the Traefik ingress controller

  - this is an arbitrary choice

  - maybe motivated by the fact that Traefik releases are named after cheeses

- For DNS, we will use [nip.io](http://nip.io/)

  - `*.1.2.3.4.nip.io` resolves to `1.2.3.4`

- We will create ingress resources for various HTTP services

---

## Deploying pods listening on port 80

- We want our ingress load balancer to be available on port 80

- We could do that with a `LoadBalancer` service

  ... but it requires support from the underlying infrastructure

- We could use pods specifying `hostPort: 80` 

  ... but with most CNI plugins, this [doesn't work or requires additional setup](https://github.com/kubernetes/kubernetes/issues/23920)

- We could use a `NodePort` service

  ... but that requires [changing the `--service-node-port-range` flag in the API server](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-apiserver/)

- Last resort: the `hostNetwork` mode

---

## Without `hostNetwork`

- Normally, each pod gets its own *network namespace*

  (sometimes called sandbox or network sandbox)

- An IP address is assigned to the pod

- This IP address is routed/connected to the cluster network

- All containers of that pod are sharing that network namespace

  (and therefore using the same IP address)

---

## With `hostNetwork: true`

- No network namespace gets created

- The pod is using the network namespace of the host

- It "sees" (and can use) the interfaces (and IP addresses) of the host

- The pod can receive outside traffic directly, on any port

- Downside: with most network plugins, network policies won't work for that pod

  - most network policies work at the IP address level

  - filtering that pod = filtering traffic from the node

---

## Running Traefik

- The [Traefik documentation](https://docs.traefik.io/user-guide/kubernetes/#deploy-trfik-using-a-deployment-or-daemonset) tells us to pick between Deployment and Daemon Set

- We are going to use a Daemon Set so that each node can accept connections

- We will do two minor changes to the [YAML provided by Traefik](https://github.com/containous/traefik/blob/v1.7/examples/k8s/traefik-ds.yaml):

  - enable `hostNetwork`

  - add a *toleration* so that Traefik also runs on `node1`

---

## Taints and tolerations

- A *taint* is an attribute added to a node

- It prevents pods from running on the node

- ... Unless they have a matching *toleration*

- When deploying with `kubeadm`:

  - a taint is placed on the node dedicated to the control plane

  - the pods running the control plane have a matching toleration

---

class: extra-details

## Checking taints on our nodes

.exercise[

- Check our nodes specs:
  ```bash
  kubectl get node node1 -o json | jq .spec
  kubectl get node node2 -o json | jq .spec
  ```

]

We should see a result only for `node1` (the one with the control plane):

```json
  "taints": [
    {
      "effect": "NoSchedule",
      "key": "node-role.kubernetes.io/master"
    }
  ]
```

---

class: extra-details

## Understanding a taint

- The `key` can be interpreted as:

  - a reservation for a special set of pods
    <br/>
    (here, this means "this node is reserved for the control plane")

  - an error condition on the node
    <br/>
    (for instance: "disk full," do not start new pods here!)

- The `effect` can be:

  - `NoSchedule` (don't run new pods here)

  - `PreferNoSchedule` (try not to run new pods here)

  - `NoExecute` (don't run new pods and evict running pods)

---

class: extra-details

## Checking tolerations on the control plane

.exercise[

- Check tolerations for CoreDNS:
  ```bash
  kubectl -n kube-system get deployments coredns -o json |
          jq .spec.template.spec.tolerations
  ```

]

The result should include:
```json
  {
    "effect": "NoSchedule",
    "key": "node-role.kubernetes.io/master"
  }
```

It means: "bypass the exact taint that we saw earlier on `node1`."

---

class: extra-details

## Special tolerations

.exercise[

- Check tolerations on `kube-proxy`:
  ```bash
  kubectl -n kube-system get ds kube-proxy -o json | 
          jq .spec.template.spec.tolerations
  ```

]

The result should include:
```json
  {
    "operator": "Exists"
  }
```

This one is a special case that means "ignore all taints and run anyway."

---

## Running Traefik on our cluster

- We provide a YAML file (`k8s/traefik.yaml`) which is essentially the sum of:

  - [Traefik's Daemon Set resources](https://github.com/containous/traefik/blob/v1.7/examples/k8s/traefik-ds.yaml) (patched with `hostNetwork` and tolerations)

  - [Traefik's RBAC rules](https://github.com/containous/traefik/blob/v1.7/examples/k8s/traefik-rbac.yaml) allowing it to watch necessary API objects

.exercise[

- Apply the YAML:
  ```bash
  kubectl apply -f ~/container.training/k8s/traefik.yaml
  ```

]

---

## Checking that Traefik runs correctly

- If Traefik started correctly, we now have a web server listening on each node

.exercise[

- Check that Traefik is serving 80/tcp:
  ```bash
  curl localhost
  ```

]

We should get a `404 page not found` error.

This is normal: we haven't provided any ingress rule yet.

---

## Setting up DNS

- To make our lives easier, we will use [nip.io](http://nip.io)

- Check out `http://cheddar.A.B.C.D.nip.io`

  (replacing A.B.C.D with the IP address of `node1`)

- We should get the same `404 page not found` error

  (meaning that our DNS is "set up properly", so to speak!)

---

## Traefik web UI

- Traefik provides a web dashboard

- With the current install method, it's listening on port 8080

.exercise[

- Go to `http://node1:8080` (replacing `node1` with its IP address)

<!-- ```open http://node1:8080``` -->

]

---

## Setting up host-based routing ingress rules

- We are going to use `errm/cheese` images

  (there are [3 tags available](https://hub.docker.com/r/errm/cheese/tags/): wensleydale, cheddar, stilton)

- These images contain a simple static HTTP server sending a picture of cheese

- We will run 3 deployments (one for each cheese)

- We will create 3 services (one for each deployment)

- Then we will create 3 ingress rules (one for each service)

- We will route `<name-of-cheese>.A.B.C.D.nip.io` to the corresponding deployment

---

## Running cheesy web servers

.exercise[

- Run all three deployments:
  ```bash
  kubectl create deployment cheddar --image=errm/cheese:cheddar
  kubectl create deployment stilton --image=errm/cheese:stilton
  kubectl create deployment wensleydale --image=errm/cheese:wensleydale
  ```

- Create a service for each of them:
  ```bash
  kubectl expose deployment cheddar --port=80
  kubectl expose deployment stilton --port=80
  kubectl expose deployment wensleydale --port=80
  ```

]

---

## What does an ingress resource look like?

Here is a minimal host-based ingress resource:

```yaml
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: cheddar
spec:
  rules:
  - host: cheddar.`A.B.C.D`.nip.io
    http:
      paths:
      - path: /
        backend:
          serviceName: cheddar
          servicePort: 80

```

(It is in `k8s/ingress.yaml`.)

---

## Creating our first ingress resources

.exercise[

- Edit the file `~/container.training/k8s/ingress.yaml`

- Replace A.B.C.D with the IP address of `node1`

- Apply the file

- Open http://cheddar.A.B.C.D.nip.io

]

(An image of a piece of cheese should show up.)

---

## Creating the other ingress resources

.exercise[

- Edit the file `~/container.training/k8s/ingress.yaml`

- Replace `cheddar` with `stilton` (in `name`, `host`, `serviceName`)

- Apply the file

- Check that `stilton.A.B.C.D.nip.io` works correctly

- Repeat for `wensleydale`

]

---

## Using multiple ingress controllers

- You can have multiple ingress controllers active simultaneously

  (e.g. Traefik and NGINX)

- You can even have multiple instances of the same controller

  (e.g. one for internal, another for external traffic)

- The `kubernetes.io/ingress.class` annotation can be used to tell which one to use

- It's OK if multiple ingress controllers configure the same resource

  (it just means that the service will be accessible through multiple paths)

---

## Ingress: the good

- The traffic flows directly from the ingress load balancer to the backends

  - it doesn't need to go through the `ClusterIP`

  - in fact, we don't even need a `ClusterIP` (we can use a headless service)

- The load balancer can be outside of Kubernetes

  (as long as it has access to the cluster subnet)

- This allows the use of external (hardware, physical machines...) load balancers

- Annotations can encode special features

  (rate-limiting, A/B testing, session stickiness, etc.)

---

## Ingress: the bad

- Aforementioned "special features" are not standardized yet

- Some controllers will support them; some won't

- Even relatively common features (stripping a path prefix) can differ:

  - [traefik.ingress.kubernetes.io/rule-type: PathPrefixStrip](https://docs.traefik.io/user-guide/kubernetes/#path-based-routing)

  - [ingress.kubernetes.io/rewrite-target: /](https://github.com/kubernetes/contrib/tree/master/ingress/controllers/nginx/examples/rewrite)

- This should eventually stabilize

  (remember that ingresses are currently `apiVersion: networking.k8s.io/v1beta1`)
