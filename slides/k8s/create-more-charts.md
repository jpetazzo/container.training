# Creating Helm charts

- We are going to create a generic Helm chart

- We will use that Helm chart to deploy DockerCoins

- Each component of DockerCoins will have its own *release*

- In other words, we will "install" that Helm chart multiple times

  (one time per component of DockerCoins)

---

## Creating a generic chart

- Rather than starting from scratch, we will use `helm create`

- This will give us a basic chart that we will customize

.exercise[

- Create a basic chart:
  ```bash
  cd ~
  helm create helmcoins
  ```

]

This creates a basic chart in the directory `helmcoins`.

---

## What's in the basic chart?

- The basic chart will create a Deployment and a Service

- Optionally, it will also include an Ingress

- If we don't pass any values, it will deploy the `nginx` image

- We can override many things in that chart

- Let's try to deploy DockerCoins components with that chart!

---

## Writing `values.yaml` for our components

- We need to write one `values.yaml` file for each component

  (hasher, redis, rng, webui, worker)

- We will start with the `values.yaml` of the chart, and remove what we don't need

- We will create 5 files:

  hasher.yaml, redis.yaml, rng.yaml, webui.yaml, worker.yaml

---

## Getting started

- For component X, we want to use the image dockercoins/X:v0.1

  (for instance, for rng, we want to use the image dockercoins/rng:v0.1)

- Exception: for redis, we want to use the official image redis:latest

.exercise[

- Write minimal YAML files for the 5 components, specifying only the image

]

--

*Hint: our YAML files should look like this.*

```yaml
### rng.yaml
image:
  repository: dockercoins/`rng`
  tag: v0.1
```

---

## Deploying DockerCoins components

- For convenience, let's work in a separate namespace

.exercise[

- Create a new namespace:
  ```bash
  kubectl create namespace helmcoins
  ```

- Switch to that namespace:
  ```bash
  kns helmcoins
  ```

]

---

## Deploying the chart

- To install a chart, we can use the following command:
  ```bash
  helm install [--name `X`] <chart>
  ```

- We can also use the following command, which is idempotent:
  ```bash
  helm upgrade --install `X` chart
  ```

.exercise[

- Install the 5 components of DockerCoins:
  ```bash
    for COMPONENT in hasher redis rng webui worker; do
      helm upgrade --install $COMPONENT helmcoins/ --values=$COMPONENT.yaml
    done
  ```

]

---

## Checking what we've done

- Let's see if DockerCoins is working!

.exercise[

- Check the logs of the worker:
  ```bash
  stern worker
  ```

- Look at the resources that were created:
  ```bash
  kubectl get all
  ```

]

There are *many* issues to fix!

---

## Service names

- Our services should be named `rng`, `hasher`, etc., but they are named differently

- Look at the YAML template used for the services

- Does it look like we can override the name of the services?

--

- *Yes*, we can use `.Values.nameOverride`

- This means setting `nameOverride` in the values YAML file

---

## Setting service names

- Let's add `nameOverride: X` in each values YAML file!

  (where X is hasher, redis, rng, etc.)

.exercise[

- Edit the 5 YAML files to add `nameOverride: X`

- Deploy the updated Chart:
  ```bash
    for COMPONENT in hasher redis rng webui worker; do
      helm upgrade --install $COMPONENT helmcoins/ --values=$COMPONENT.yaml
    done
  ```
  (Yes, this is exactly the same command as before!)

]

---

## Checking what we've done

.exercise[

- Check the service names:
  ```bash
  kubectl get services
  ```
  Great! (We have a useless service for `worker`, but let's ignore it for now.)

- Check the state of the pods:
  ```bash
  kubectl get pods
  ```
  Not so great... Some pods are *not ready.*

]

---

## Troubleshooting pods

- The easiest way to troubleshoot pods is to look at *events*

- We can look at all the events on the cluster (with `kubectl get events`)

- Or we can use `kubectl describe` on the objects that have problems

  (`kubectl describe` will retrieve the events related to the object)

.exercise[

- Check the events for the redis pods:
  ```bash
  kubectl describe pod -l app.kubernetes.io/name=redis
  ```

]

What's going on?

---

## Healthchecks

- The default chart defines healthchecks doing HTTP requests on port 80

- That won't work for redis and worker

  (redis is not HTTP, and not on port 80; worker doesn't even listen)

--

- We could comment out the healthchecks

- We could also make them conditional

- This sounds more interesting, let's do that!

---

## Conditionals

- We need to enclose the healthcheck block with:

  `{{ if CONDITION }}` at the beginning

  `{{ end }}` at the end

- For the condition, we will use `.Values.healthcheck`

---

## Updating the deployment template

.exercise[

- Edit `helmcoins/templates/deployment.yaml`

- Before the healthchecks section (it starts with `livenessProbe:`), add:

  `{{ if .Values.healthcheck }}`

- After the healthchecks section (just before `resources:`), add:

  `{{ end }}`

- Edit `hasher.yaml`, `rng.yaml`, `webui.yaml` to add:

  `healthcheck: true`

]

---

## Update the deployed charts

- We can now apply the new templates (and the new values)

.exercise[

- Use the same command as earlier to upgrade all five components

- Use `kubectl describe` to confirm that `redis` starts correctly

- Use `kubectl describe` to confirm that `hasher` still has healthchecks

]

---

## Is it working now?

- If we look at the worker logs, it appears that the worker is still stuck

- What could be happening?

--

- The redis service is not on port 80!

- We need to update the port number in redis.yaml

- We also need to update the port number in deployment.yaml

  (it is hard-coded to 80 there)

---

## Setting the redis port

.exercise[

- Edit `redis.yaml` to add:
  ```yaml
    service:
      port: 6379
  ```

- Edit `helmcoins/templates/deployment.yaml`

- The line with `containerPort` should be:
  ```yaml
  containerPort: {{ .Values.service.port }}
  ```

]

---

## Apply changes

- Re-run the for loop to execute `helm upgrade` one more time

- Check the worker logs

- This time, it should be working!

---

## Extra steps

- We don't need to create a service for the worker

- We can put the whole service block in a conditional

  (this will require additional changes in other files referencing the service)

- We can set the webui to be a NodePort service

- We can change the number of workers with `replicaCount`

- And much more!
