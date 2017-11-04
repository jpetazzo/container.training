# The Kubernetes dashboard

- Kubernetes resources can also be viewed with a web dashboard

- We are going to deploy that dashboard with *three commands:*

  - one to actually *run* the dashboard

  - one to make the dashboard available from outside

  - one to bypass authentication for the dashboard

--

.footnote[.warning[Yes, this will open our cluster to all kinds of shenanigans. Don't do this at home.]]

---

## Running the dashboard

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

## Making the dashboard reachable from outside

- The dashboard is exposed through a `ClusterIP` service

- We need a `NodePort` service instead

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

.exercise[

- Edit the service:
  ```bash
  kubectl -n kube-system edit service kubernetes-dashboard
  ```

- Change `ClusterIP` to `NodePort`, save, and exit

- Check the port that was assigned with `kubectl -n kube-system get services`

]

---

## Connecting to the dashboard

.exercise[

- Connect to https://oneofournodes:3xxxx/

  (You will have to work around the TLS certificate validation warning)

<!-- ```open https://node1:3xxxx/``` -->

]

- We have three authentication options at this point:

  - token (associated with a role that has appropriate permissions)

  - kubeconfig (e.g. using the `~/.kube/config` file from `node1`)

  - "skip" (use the dashboard "service account")

- Let's use "skip": we get a bunch of warnings and don't see much

---

## Granting more rights to the dashboard

- The dashboard documentation [explains how to do](https://github.com/kubernetes/dashboard/wiki/Access-control#admin-privileges)

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
