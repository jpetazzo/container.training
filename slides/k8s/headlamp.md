# Headlamp

- Kubernetes has a [web dashboard][k8s-dashboard], but it's deprecated

- It has been superseded by [Headlamp][headlamp]

- Headlamp can be used:

  - as a local desktop app

  - as a web app on a Kubernetes cluster ("in-cluster")

- Headlamp can be used to access multiple clusters

  (even when used in-cluster)

[k8s-dashboard]: https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/
[headlamp]: https://headlamp.dev/

---

## Desktop app

- Headlamp will use our `kubeconfig` file

  (exactly like `kubectl` does)

- Headlamp will use our Kubernetes permissions

  (we will have exactly the same permissions as we had with `kubectl`)

- To try Headlamp:

  - [download it][download-headlamp] for your platform

  - run it

  - select the cluster you want to use and click "connect"

  - then click on the cluster name

[download-headlamp]: https://headlamp.dev/#download-platforms

---

## In-cluster deployment

- Step 1: run Headlamp on our cluster

  (by installing a Helm chart or applying some YAML)

- Step 2: obtain a *token*

  (conceptually similar to a login+password)

- Step 3: connect to Headlamp

---

## Installing Headlamp in-cluster

- The recommended method is to use the Helm chart

  (it makes it easier to customize and adjust settings)

.lab[

- Add the Headlamp Helm repo:
  ```bash
  helm repo add headlamp https://kubernetes-sigs.github.io/headlamp/
  ```

- Install the Helm chart:
  ```bash
  helm install headlamp headlamp/headlamp --namespace kube-system
  ```

]

- If you prefer to use plain YAML, check the [installation documentation][headlamp-install-doc].

[headlamp-install-doc]: https://headlamp.dev/docs/latest/installation/in-cluster/#using-simple-yaml

---

## Obtaining a token

- Standard Kubernetes authentication token

  (JWT - JSON Web Token; also used by ServiceAccounts)

- By default, Headlamp creates a `headlamp` ServiceAccount

- That ServiceAccount has `cluster-admin` privileges

  (= all permissions on the entire cluster)

.lab[

- Create a token for that ServiceAccount:
  ```bash
  kubectl create token headlamp --namespace kube-system --duration=4h
  ```

]

.warning[This token gives `cluster-admin` privileges! It's like being `root` on the whole cluster.]

---

## Connecting to in-cluster headlamp

- By default, Headlamp isn't exposed to the outside world

- If we want a temporary access to Headlamp:

  *use `kubectl port-forward` to access Headlamp's service*

- If we want to expose it permanently:

  *expose Headlamp with an Ingress, HTTPRoute, NodePort, LoadBalancer...*

- For simplicity, we're going to use `kubectl port-forward` here

---

## Exposing Headlamp

- If we run `kubectl` on our local machine:

  `kubectl port-forward service/headlamp -n kube-system 1234:80`

  *...then connect to http://localhost:1234*

- If we run `kubectl` on a remote cluster:

  `kubectl patch service/headlamp -n kube-system --patch '{"spec": {"type": "NodePort"}}'`

  `kubectl get service/headlamp -n kube-system`

  *...then connect to the allocated `NodePort`.*

- Use the token generated earlier to authenticate

---

## Things to do with Headlamp

- Click on `Nodes` to view cluster composition and load

- Click on `Workloads` to see Pods, Deployments, DaemonSets, etc.

- Click on `Network` to see Services, Ingresses, HTTPRoutes, etc.

- Click on `Create` (lower left corner), then:

  - copy-paste YAML

  - or go to the `Form` tab fod guided resource creation

  - then click back on `Editor` to see a template for the selected resource

???

:EN:- The Headlamp dashboard
:FR:- Le tableau de bord Headlamp
