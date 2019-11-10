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

.exercise[

- Deploy or redeploy Dockercoins:
  ```bash
  kubectl apply -f ~/container.training/k8s/dockercoins.yaml
  ```

]

(If we deployed Dockercoins earlier, we will see warning messages,
because the resources that we created lack the necessary annotation.
We can safely ignore them.)

