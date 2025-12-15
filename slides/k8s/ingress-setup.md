# Setting up an Ingress Controller

- We're going to install Traefik as our Ingress Controller

  - arbitrary choice; but it has a nice dashboard, which is helpful when troubleshooting

  - also, Traefik releases are named after tasty cheeses :)

- We're going to install it using the official Helm chart

  - also an arbitrary choice; but a fairly straightforward one

  - Helm charts can easily fit in other tools (like Flux, ArgoCD, Terraform/OpenTofu...)

- There can be some differences depending on how we want to handle inbound traffic

- Let's review the different possibilities!

---

## Scenario 1: `LoadBalancer` Service

- This is the default option for most Ingress Controllers

  (i.e. what you get if you install their Helm charts without further configuration)

- It requires a cluster where `LoadBalancer` Services are available

  - most cloud-based, managed clusters support `LoadBalancer` Services

  - on-premises clusters can also support them with e.g. [MetalLB] or [kube-vip])

- The Ingress Controller runs with a Deployment

  (typically scaled to at least two replicas, to ensure high availability)

- It is exposed with a `LoadBalancer` Service

---

## Scenario 2: `hostPort`

- This is a good fallback option when `LoadBalancer` Services aren't available

- It typically requires extra configuration steps or options when installing the controller

- It requires a cluster where at least some Nodes have public IP addresses

- The Ingress Controller runs with a DaemonSet

  (potentially with a `nodeSelector` to restrict it to a specific set of nodes)

- The Ingress Controller Pods are exposed by using one (or multiple) `hostPort`

- `hostPort` creates a direct port mapping on the Node, for instance:

  *port 80 on the Node → port 8080 in the Pod*

- It can also create a shorter, faster path to the application Pods

---

## Scenario 3: `hostNetwork`

- This is similar to `hostPort`

  (but a bit less secure)

- Ingress controller Pods run with `hostNetwork: true`

- This lets the Pods use the network stack of the Node that they're running on

- When the Ingress Controller binds to port 80, it means "port 80 on the Node"

- The Ingress Controller must be given permissions to bind to ports below 1024

  (it must either run as root, or leverage `NET_BIND_SERVICE` capability accordingly)

- The Ingress Controller can potentially bind to any port on the Node

  (this might not be desirable!)

---

## Scenario 4: `externalIPs`

- Heads up, this is a rather exotic scenario, but here we go!

- It's possible to [manually assign `externalIPs` to a Service][externalips]

  (including `ClusterIP` services)

- When TCP connections (or UDP packets) destined to an `externalIP` reach a Node...

  ...the Node will forward these connections or packets to the relevant Pods

- This requires manual management of a pool of available `externalIPs`

- It also requires some network engineering so that the traffic reaches the Nodes

  (in other words: just setting `externalIPs` on Services won't be enough!)

- This is how some controllers like [MetalLB] or [kube-vip] operate

[externalips]: https://kubernetes.io/docs/concepts/services-networking/service/#external-ips

---

## Scenario 5: local dev clusters

- Local dev clusters are typically not reachable from the outside world

- They rarely have `LoadBalancer` Services

  (when they do, they use local addresses, and are sometimes limited to a single one)

- Their Nodes might not be directly reachable

  (making the `hostPort` and `hostNetwork` strategies impractical)

- In some cases, it's possible to map a port on our machine to a port on the dev cluster

  (e.g. [KinD has an `extraPortMappings` option][kind-extraportmappings])

- We can also use `kubectl port-forward` to test our local Ingress Controller

[kind-extraportmappings]: https://kind.sigs.k8s.io/docs/user/configuration/#extra-port-mappings

---

class: extra-details

## Local clusters details

- When using Docker-based clusters on Linux:

  *connect directly to the node's IP address (172.X.Y.Z)*

- When using Docker-based clusters with Docker Desktop:

  *set up port mapping (then connect to localhost:XYZ)*

- Generic scenario:

  *run `kubectl port-forward 8888:80` to the Ingress Controller*
  <br/>
  *(and then connect to `http://localhost:8888`)*

---

class: extra-details

## Why not a `NodePort` Service?

- Node ports are typically in the 30000-32767 range

- Web site users don't want to specify port numbers

  (e.g. "connect to https://blahblah.whatever:31550")

- Our Ingress Controller needs to actually be exposed on port 80

  (and 443 if we want to handle HTTPS)

---

## Installing Traefik with a `LoadBalancer`

- We're going to use the official Helm chart

  (https://artifacthub.io/packages/helm/traefik/traefik)

- Its default configuration values should work out of the box

  (as long as our cluster supports `LoadBalancer` Services!)

.lab[

- Install the Traefik Helm chart:
  ```bash
    helm upgrade --install --repo https://traefik.github.io/charts \
         traefik traefik --namespace traefik --create-namespace \
         --version 37.4.0
  ```

]

- That's it; now let's send it a test request!

---

## Retrieving the Ingress Controller address

- Our Ingress Controller uses a `LoadBalancer` Service

- We want to obtain that Service's `EXTERNAL-IP`

.lab[

- Retrieve the `EXTERNAL-IP` that has been allocated to the Service:
  ```bash
  kubectl get services --namespace=traefik
  ```

- Send a test request; it should show `404 not found`:
  ```bash
  curl http://`<EXTERNAL-IP>`
  ```

]

- Note: that `EXTERNAL-IP` might be `<Pending>` for a little while before showing up

  (in that case, just try again a few seconds later)

---

class: extra-details

## Scripting it

- If we want to include these steps in a script, here's what we can do!

.lab[

- Use `kubectl wait` to wait until a specific field exists in the resource:
  ```bash
    kubectl wait service traefik --namespace=traefik \
            --for=jsonpath=.status.loadBalancer.ingress
  ```

- Then extract the IP address:
  ```bash
    kubectl get service traefik --namespace=traefik \
            -o jsonpath={.status.loadBalancer.ingress[0].ip}
  ```

]

- Note: on some providers like AWS, you might have to use `.hostname` instead of `.ip`

- Note: there might be multiple addresses; the command above returns only the first one

---

class: extra-details

## Make it production-ready

- To improve the availability of our Ingress Controller:

  - configure at least 2 replicas (in case of Node outage)

  - add a `podAntiAffinity` (to make sure Pods are not all in the same place)

  - add a PodDisruptionBudget (to handle planned maintenance, e.g. cluster ugprades)

  - set resource requests and limits for CPU and RAM

- To monitor our Ingress Controller:

  - collect the metrics exposed by Traefik (e.g. with Prometheus)

  - set up some alerting (e.g. with [stakater/IngressMonitorController])

[stakater/IngressMonitorController]: https://github.com/stakater/IngressMonitorController

---

## Installing Traefik with a `DaemonSet` + `hostPort`

- The plan is to run one Traefik Pod on each Node of the cluster

- For that, we need a `DaemonSet` instead of a `Deployment`

- Instead of a `LoadBalancer` Service, we'll use a `hostPort`

  (actually, multiple `hostPort`; at least one for HTTP and one for HTTPS)

- Let's see how to do that with the Traefik Helm chart!

- We'll be looking at the chart's [default values] and [values schema]

[default values]: https://artifacthub.io/packages/helm/traefik/traefik?modal=values
[values schema]: https://artifacthub.io/packages/helm/traefik/traefik?modal=values-schema

---

## Switching to a `DaemonSet`

- In the chart's [default values], looking for the string `DaemonSet` gives us this:
  ```yaml
    deployment:
      # -- Enable deployment
      enabled: true
      # -- Deployment or `DaemonSet`
      kind: Deployment
  ```

- This means we need to set `deployment.kind=DaemonSet`!

---

## Using `hostPort`

- In the chart's [default values], we find 3 references mentioning `hostPort`:
  .small[
  ```yaml
ports:
      traefik:
        port: 8080
        # -- Use hostPort if set.
        `hostPort`:  # @schema type:[integer, null]; minimum:0
      ...
      web:
        ## -- Enable this entrypoint as a default entrypoint. When a service doesn't explicitly set an entrypoint ...
        # asDefault: true
        port: 8000
        # `hostPort`: 8000
      ...
      websecure:
        ## -- Enable this entrypoint as a default entrypoint. When a service doesn't explicitly set an entrypoint ...
        # asDefault: true
        port: 8443
        `hostPort`:  # @schema type:[integer, null]; minimum:0      
  ```
  ]

- This deserves a small explanation about the Traefik concept of "entrypoint"!

---

## Traefik "entrypoints"

- An entrypoint in Traefik is basically an open port

- Common Traefik configurations will have 3 entrypoints (3 open ports):

  - `web` for HTTP traffic 

  - `websecure` for HTTPS traffic

  - `traefik` for Traefik dashboard and API

- We'll set `ports.web.hostPort=80` and `ports.websecure.hostPort=443`

⚠️ Traefik entrypoints are totally unrelated to `ENTRYPOINT` in Dockerfiles!

---

## Traefik Service

- By default, the Helm chart creates a `LoadBalancer` Service

- We don't need that anymore, so we can either:

  - disable it altogether (`service.enabled=false`)

  - switch it to a `ClusterIP` service (`service.type=ClusterIP`)

- Either option is fine!

---

## Putting it all together

- We're going to use a bunch of `--set` flags with all the options that we gathered

- We could also put them in a YAML file and use `--values`

.lab[

- Install Traefik with all our options:
  ```bash
    helm upgrade --install --repo https://traefik.github.io/charts \
         traefik traefik --namespace traefik --create-namespace \
         --set deployment.kind=DaemonSet \
         --set ports.web.hostPort=80 \
         --set ports.websecure.hostPort=443 \
         --set service.type=ClusterIP \
         --version 37.4.0
  ```

]

---

## Testing our Ingress Controller

- We should be able to connect to *any* Node of the cluster, on port 80

.lab[

- Send a test request:
  ```bash
  curl http://`<node address/`
  ```

]

- We should see `404 not found`

---

class: extra-details

## Control plane nodes

- When running Kubernetes on-premises, it's typical to have "control plane nodes"

- These nodes are dedicated to the control plane Pods, and won't run normal workloads

- If you have such a cluster (e.g. deployed with `kubeadm` on multiple nodes):

  - get the list of nodes (`kubectl get nodes`)

  - check where Traefik Pods are running (`kubectl get pods --namespace=traefik`)

- You should see that Traefik is not running on control plane nodes!

---

class: extra-details

## Running Traefik on the control plane

- If we want to do that, we need to provide a *toleration*

- That toleration needs to match the *taint* on the control plane nodes

- To review the taints on our nodes, we can use one of these commands:
  ```bash
  kubectl get nodes -o custom-columns=NAME:metadata.name,TAINTS:spec.taints
  kubectl get nodes -o json | jq '.items[] | [.metadata.name, .spec.taints]'
  ```

- Then, to place the proper toleration on Traefik pods:
  ```bash
  --set tolerations[0].key=node-role.kubernetes.io/control-plane
  --set tolerations[0].effect=NoSchedule
  ```

- Note: as we keep adding options, writing a values YAML file becomes more convenient!

---

## What about local dev clusters?

- Follow the instructions for "normal" clusters (with a `LoadBalancer` service)

- Once Traefik is up and running, set up a port-forward:
  ```bash
  kubectl port-forward --namespace=traefik service/traefik 8888:80
  ```

- Connect to http://localhost:8888

- You should see a `404 not found` served by Traefik

- Whenever you'll need the "IP address of the Ingress Controller", use `localhost:8888`

  (you'll need to specify that port number)

- With some clusters (e.g. KinD) it's also possible to set up local port mappings
  to avoid specifying the port number; but the port-forward method should work everywhere

---

## The Traefik dashboard

- Accessing the Traefik dashboard requires multiple steps

- First, the dashboard feature needs to be enabled in Traefik

  *the Helm chart does this automatically by default*

- Next, there needs to be a "route" inside Traefik to expose the dashboard

  *this can be done by setting `ingressRoute.dashboard.enabled=true`*

- Finally, we need to connect to the correct entrypoint

  *by default, that will be the internal entrypoint on port 8080, on `/dashboard`*

---

## Accessing the Traefik dashboard

- Redeploy Traefik, adding `--set ingressRoute.dashboard.enabled=true`

- Then use port-forward to access the internal `traefik` entrypoint:
  ```bash
  kubectl port-forward --namespace=traefik deployment/traefik 1234:8080
  kubectl port-forward --namespace=traefik daemonset/traefik 1234:8080
  ```
  (use the appropriate command depending on how you're running Traefik)

- Connect to http://localhost:1234/dashboard/ (with the trailing slash!)

- You should see the Traefik dashboard!

- Note: it's only available on the internal port, but there is no authentication by default!

  (you might want to add authentication or e.g. set up a NetworkPolicy to secure it)

???

[MetalLB]: https://metallb.org/
[kube-vip]: https://kube-vip.io/

:EN:- Setting up an Ingress Controller
:FR:- Mise en place d'un Ingress Controller
