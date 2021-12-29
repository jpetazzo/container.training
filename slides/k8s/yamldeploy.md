# Deploying with YAML

- So far, we created resources with the following commands:

  - `kubectl run`

  - `kubectl create deployment`

  - `kubectl expose`

- We can also create resources directly with YAML manifests

---

## `kubectl apply` vs `create`

- `kubectl create -f whatever.yaml`

  - creates resources if they don't exist

  - if resources already exist, don't alter them
    <br/>(and display error message)

- `kubectl apply -f whatever.yaml`

  - creates resources if they don't exist

  - if resources already exist, update them
    <br/>(to match the definition provided by the YAML file)

  - stores the manifest as an *annotation* in the resource

---

## Creating multiple resources

- The manifest can contain multiple resources separated by `---`

```yaml
 kind: ...
 apiVersion: ...
 metadata: ...
   name: ...
 ...
 ---
 kind: ...
 apiVersion: ...
 metadata: ...
   name: ...
 ...
```

---

## Creating multiple resources

- The manifest can also contain a list of resources

```yaml
 apiVersion: v1
 kind: List
 items:
 - kind: ...
   apiVersion: ...
   ...
 - kind: ...
   apiVersion: ...
   ...
```

---

## Deploying dockercoins with YAML

- We provide a YAML manifest with all the resources for Dockercoins

  (Deployments and Services)

- We can use it if we need to deploy or redeploy Dockercoins

.lab[

- Deploy or redeploy Dockercoins:
  ```bash
  kubectl apply -f ~/container.training/k8s/dockercoins.yaml
  ```

]

(If we deployed Dockercoins earlier, we will see warning messages,
because the resources that we created lack the necessary annotation.
We can safely ignore them.)

---

## Deleting resources

- We can also use a YAML file to *delete* resources

- `kubectl delete -f ...` will delete all the resources mentioned in a YAML file

  (useful to clean up everything that was created by `kubectl apply -f ...`)

- The definitions of the resources don't matter

  (just their `kind`, `apiVersion`, and `name`)

---

## Pruning¹ resources

- We can also tell `kubectl` to remove old resources

- This is done with `kubectl apply -f ... --prune`

- It will remove resources that don't exist in the YAML file(s)

- But only if they were created with `kubectl apply` in the first place

  (technically, if they have an annotation `kubectl.kubernetes.io/last-applied-configuration`)

.footnote[¹If English is not your first language: *to prune* means to remove dead or overgrown branches in a tree, to help it to grow.]

---

## YAML as source of truth

- Imagine the following workflow:

  - do not use `kubectl run`, `kubectl create deployment`, `kubectl expose` ...

  - define everything with YAML

  - `kubectl apply -f ... --prune --all` that YAML

  - keep that YAML under version control

  - enforce all changes to go through that YAML (e.g. with pull requests)

- Our version control system now has a full history of what we deploy

- Compares to "Infrastructure-as-Code", but for app deployments

---

class: extra-details

## Specifying the namespace

- When creating resources from YAML manifests, the namespace is optional

- If we specify a namespace:

  - resources are created in the specified namespace

  - this is typical for things deployed only once per cluster

  - example: system components, cluster add-ons ...

- If we don't specify a namespace:

  - resources are created in the current namespace

  - this is typical for things that may be deployed multiple times

  - example: applications (production, staging, feature branches ...)

???

:EN:- Deploying with YAML manifests
:FR:- Déployer avec des *manifests* YAML
