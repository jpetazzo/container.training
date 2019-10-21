# The Kubernetes dashboard

- Kubernetes resources can also be viewed with a web dashboard

- That dashboard is usually exposed over HTTPS

  (this requires obtaining a proper TLS certificate)

- Dashboard users need to authenticate

- We are going to take a *dangerous* shortcut

---

## The insecure method

- We could (and should) use [Let's Encrypt](https://letsencrypt.org/) ...

- ... but we don't want to deal with TLS certificates

- We could (and should) learn how authentication and authorization work ...

- ... but we will use a guest account with admin access instead

.footnote[.warning[Yes, this will open our cluster to all kinds of shenanigans. Don't do this at home.]]

---

## Running a very insecure dashboard

- We are going to deploy that dashboard with *one single command*

- This command will create all the necessary resources

  (the dashboard itself, the HTTP wrapper, the admin/guest account)

- All these resources are defined in a YAML file

- All we have to do is load that YAML file with with `kubectl apply -f`

.exercise[

- Create all the dashboard resources, with the following command:
  ```bash
  kubectl apply -f ~/container.training/k8s/insecure-dashboard.yaml
  ```

]

---

## Connecting to the dashboard

.exercise[

- Check which port the dashboard is on:
  ```bash
  kubectl get svc dashboard
  ```

]

You'll want the `3xxxx` port.


.exercise[

- Connect to http://oneofournodes:3xxxx/

<!-- ```open http://node1:3xxxx/``` -->

]

The dashboard will then ask you which authentication you want to use.

---

## Dashboard authentication

- We have three authentication options at this point:

  - token (associated with a role that has appropriate permissions)

  - kubeconfig (e.g. using the `~/.kube/config` file from `node1`)

  - "skip" (use the dashboard "service account")

- Let's use "skip": we're logged in!

--

.warning[By the way, we just added a backdoor to our Kubernetes cluster!]

---

## Running the Kubernetes dashboard securely

- The steps that we just showed you are *for educational purposes only!*

- If you do that on your production cluster, people [can and will abuse it](https://redlock.io/blog/cryptojacking-tesla)

- For an in-depth discussion about securing the dashboard,
  <br/>
  check [this excellent post on Heptio's blog](https://blog.heptio.com/on-securing-the-kubernetes-dashboard-16b09b1b7aca)

---

## Other dashboards

- [Kube Web View](https://codeberg.org/hjacobs/kube-web-view)

  - read-only dashboard

  - optimized for "troubleshooting and incident response"

  - see [vision and goals](https://kube-web-view.readthedocs.io/en/latest/vision.html#vision) for details

- [Kube Ops View](https://github.com/hjacobs/kube-ops-view)

  - "provides a common operational picture for multiple Kubernetes clusters"

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

- Example: the official setup instructions for most pod networks

--

- It introduces new failure modes

  (for instance, if you try to apply YAML from a link that's no longer valid)
