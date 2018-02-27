# The Kubernetes dashboard

- Kubernetes resources can also be viewed with a web dashboard

- We are going to deploy that dashboard with *three commands:*

  1) actually *run* the dashboard

  2) bypass SSL for the dashboard

  3) bypass authentication for the dashboard

--

There is an additional step to make the dashboard available from outside (we'll get to that)

--

.footnote[.warning[Yes, this will open our cluster to all kinds of shenanigans. Don't do this at home.]]

---

## 1) Running the dashboard

- We need to create a *deployment* and a *service* for the dashboard

- But also a *secret*, a *service account*, a *role* and a *role binding*

- All these things can be defined in a YAML file and created with `kubectl apply -f`

.exercise[

- Create all the dashboard resources, with the following command:
  ```bash
  kubectl apply -f https://goo.gl/Qamqab
  ```

]

The goo.gl URL expands to:
<br/>
.small[https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml]

---


## 2) Bypass SSL for the dashboard

The Kubernetes dashboard uses https, but we don't have a certificate

Chrome 63 (and later) as well as recent versions of Edge will refuse to connect

In real life, we'd use something like [Let's Encrypt](https://letsencrypt.org/)

For this workshop, we'll forward http to https _(do not try this at home!)_

--

.warning[All our dashboard traffic is now clear-text, including passwords!]

--

.exercise[

- Forward http to https
  ```bash
  kubectl apply -f https://goo.gl/tA7GLz
  ```

]

The goo.gl URL expands to:
<br/>
.small[https://gist.githubusercontent.com/jpetazzo/c53a28b5b7fdae88bc3c5f0945552c04/raw/da13ef1bdd38cc0e90b7a4074be8d6a0215e1a65/socat.yaml]

---

## Connecting to the dashboard


.exercise[

- Connect to http://oneofournodes:3xxxx/

<!-- ```open https://node1:3xxxx/``` -->

]

The dashboard will then ask you which authentication you want to use.

---

## Dashboard authentication

- We have three authentication options at this point:

  - token (associated with a role that has appropriate permissions)

  - kubeconfig (e.g. using the `~/.kube/config` file from `node1`)

  - "skip" (use the dashboard "service account")

- Let's use "skip": we get a bunch of warnings and don't see much

---

## 3) Bypass authentication for the dashboard

- The dashboard documentation [explains how to do this](https://github.com/kubernetes/dashboard/wiki/Access-control#admin-privileges)

- We just need to load another YAML file!

.exercise[

- Grant admin privileges to the dashboard so we can see our resources:
  ```bash
  kubectl apply -f https://goo.gl/CHsLTA
  ```

- Reload the dashboard and enjoy!

]

--

.warning[By the way, we just added a backdoor to our Kubernetes cluster!]

---

## What about making the dashboard reachable from outside?

- We took a shortcut by forwarding http to https inside the cluster

- If we were really using https...

- Inside, the dashboard is exposed through a `ClusterIP` service

- From outside, we need a `NodePort` service instead

.exercise[

- Edit the service:
  ```bash
  kubectl edit service kubernetes-dashboard
  ```

]

--

`NotFound`?!? Y U NO WORK?!?

---

## Editing the `kubernetes-dashboard` service

- If we look at the YAML that we loaded just before, we'll get a hint

--

- The dashboard was created in the `kube-system` namespace

--

.exercise[

- Edit the service:
  ```bash
  kubectl -n kube-system edit service kubernetes-dashboard
  ```

- Change `ClusterIP` to `NodePort`, save, and exit

- Check the port that was assigned with `kubectl -n kube-system get services`

]

---

# Security implications of `kubectl apply`

- When we do `kubectl apply -f <URL>`, we create arbitrary resources

- Resources can be evil; imagine a `deployment` that ...

--

  - starts bitcoin miners on the whole cluster

--

  - hides in a non-default namespace

--

  - bind-mounts our nodes' filesystem

--

  - inserts SSH keys in the root account (on the node)

--

  - encrypts our data and ransoms it

--

  - ☠️☠️☠️

---

## `kubectl apply` is the new `curl | sh`

- `curl | sh` is convenient

- It's safe if you use HTTPS URLs from trusted sources

--

- `kubectl apply -f` is convenient

- It's safe if you use HTTPS URLs from trusted sources

--

- It introduces new failure modes

- Example: the official setup instructions for most pod networks


---
