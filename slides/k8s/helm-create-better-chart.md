# Creating better Helm charts

- We are going to create a chart with the helper `helm create`

- This will give us a chart implementing lots of Helm best practices

  (labels, annotations, structure of the `values.yaml` file ...)

- We will use that chart as a generic Helm chart

- We will use it to deploy DockerCoins

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

- In each file, we want to have:
  ```yaml
    image:
      repository: IMAGE-REPOSITORY-NAME
      tag: IMAGE-TAG
  ```

---

## Getting started

- For component X, we want to use the image dockercoins/X:v0.1

  (for instance, for rng, we want to use the image dockercoins/rng:v0.1)

- Exception: for redis, we want to use the official image redis:latest

.exercise[

- Write YAML files for the 5 components, with the following model:
  ```yaml
    image:
      repository: `IMAGE-REPOSITORY-NAME` (e.g. dockercoins/worker)
      tag: `IMAGE-TAG` (e.g. v0.1)
  ```

]

---

## Deploying DockerCoins components

- For convenience, let's work in a separate namespace

.exercise[

- Create a new namespace (if it doesn't already exist):
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
  helm install COMPONENT-NAME CHART-DIRECTORY
  ```

- We can also use the following command, which is idempotent:
  ```bash
  helm upgrade COMPONENT-NAME CHART-DIRECTORY --install
  ```

.exercise[

- Install the 5 components of DockerCoins:
  ```bash
    for COMPONENT in hasher redis rng webui worker; do
      helm upgrade $COMPONENT helmcoins --install --values=$COMPONENT.yaml
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

## Can't pull image

- It looks like our images can't be found

.exercise[

- Use `kubectl describe` on any of the pods in error

]

- We're trying to pull `rng:1.16.0` instead of `rng:v0.1`!

- Where does that `1.16.0` tag come from?

---

## Inspecting our template

- Let's look at the `templates/` directory

  (and try to find the one generating the Deployment resource)

.exercise[

- Show the structure of the `helmcoins` chart that Helm generated:
  ```bash
  tree helmcoins
  ```

- Check the file `helmcoins/templates/deployment.yaml`

- Look for the `image:` parameter

]

*The image tag references `{{ .Chart.AppVersion }}`. Where does that come from?*

---

## The `.Chart` variable

- `.Chart` is a map corresponding to the values in `Chart.yaml`

- Let's look for `AppVersion` there!

.exercise[

- Check the file `helmcoins/Chart.yaml`

- Look for the `appVersion:` parameter

]

(Yes, the case is different between the template and the Chart file.)

---

## Using the correct tags

- If we change `AppVersion` to `v0.1`, it will change for *all* deployments

  (including redis)

- Instead, let's change the *template* to use `{{ .Values.image.tag }}`

  (to match what we've specified in our values YAML files)

.exercise[

- Edit `helmcoins/templates/deployment.yaml`

- Replace `{{ .Chart.AppVersion }}` with `{{ .Values.image.tag }}`

]

---

## Upgrading to use the new template

- Technically, we just made a new version of the *chart*

- To use the new template, we need to *upgrade* the release to use that chart

.exercise[

- Upgrade all components:
  ```bash
    for COMPONENT in hasher redis rng webui worker; do
      helm upgrade $COMPONENT helmcoins
    done
  ```

- Check how our pods are doing:
  ```bash
  kubectl get pods
  ```

]

We should see all pods "Running". But ... not all of them are READY.

---

## Troubleshooting readiness

- `hasher`, `rng`, `webui` should show up as `1/1 READY`

- But `redis` and `worker` should show up as `0/1 READY`

- Why?

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

It's failing both its liveness and readiness probes!

---

## Healthchecks

- The default chart defines healthchecks doing HTTP requests on port 80

- That won't work for redis and worker

  (redis is not HTTP, and not on port 80; worker doesn't even listen)

--

- We could remove or comment out the healthchecks

- We could also make them conditional

- This sounds more interesting, let's do that!

---

## Conditionals

- We need to enclose the healthcheck block with:

  `{{ if false }}` at the beginning (we can change the condition later)

  `{{ end }}` at the end

.exercise[

- Edit `helmcoins/templates/deployment.yaml`

- Add `{{ if false }}` on the line before `livenessProbe`

- Add `{{ end }}` after the `readinessProbe` section

  (see next slide for details)

]

---

This is what the new YAML should look like (added lines in yellow):

```yaml
        ports:
          - name: http
            containerPort: 80
            protocol: TCP
        `{{ if false }}`
        livenessProbe:
          httpGet:
            path: /
            port: http
        readinessProbe:
          httpGet:
            path: /
            port: http
        `{{ end }}`
        resources:
          {{- toYaml .Values.resources | nindent 12 }}
```

---

## Testing the new chart

- We need to upgrade all the services again to use the new chart

.exercise[

- Upgrade all components:
  ```bash
    for COMPONENT in hasher redis rng webui worker; do
      helm upgrade $COMPONENT helmcoins
    done
  ```

- Check how our pods are doing:
  ```bash
  kubectl get pods
  ```

]

Everything should now be running!

---

## What's next?

- Is this working now?

.exercise[

- Let's check the logs of the worker:
  ```bash
  stern worker
  ```

]

This error might look familiar ... The worker can't resolve `redis`.

Typically, that error means that the `redis` service doesn't exist.

---

## Checking services

- What about the services created by our chart?

.exercise[

- Check the list of services:
  ```bash
  kubectl get services
  ```

]

They are named `COMPONENT-helmcoins` instead of just `COMPONENT`.

We need to change that!

---

## Where do the service names come from?

- Look at the YAML template used for the services

- It should be using `{{ include "helmcoins.fullname" }}`

- `include` indicates a *template block* defined somewhere else

.exercise[

- Find where that `fullname` thing is defined:
  ```bash
  grep define.*fullname helmcoins/templates/*
  ```

]

It should be in `_helpers.tpl`.

We can look at the definition, but it's fairly complex ...

---

## Changing service names

- Instead of that `{{ include }}` tag, let's use the name of the release

- The name of the release is available as `{{ .Release.Name }}`

.exercise[

- Edit `helmcoins/templates/service.yaml`

- Replace the service name with `{{ .Release.Name }}`

- Upgrade all the releases to use the new chart

- Confirm that the services now have the right names

]

---

## Is it working now?

- If we look at the worker logs, it appears that the worker is still stuck

- What could be happening?

--

- The redis service is not on port 80!

- Let's see how the port number is set

- We need to look at both the *deployment* template and the *service* template

---

## Service template

- In the service template, we have the following section:
  ```yaml
    ports:
    - port: {{ .Values.service.port }}
      targetPort: http
      protocol: TCP
      name: http
  ```

- `port` is the port on which the service is "listening"

  (i.e. to which our code needs to connect)

- `targetPort` is the port on which the pods are listening

- The `name` is not important (it's OK if it's `http` even for non-HTTP traffic)

---

## Setting the redis port

- Let's add a `service.port` value to the redis release

.exercise[

- Edit `redis.yaml` to add:
  ```yaml
    service:
      port: 6379
  ```

- Apply the new values file:
  ```bash
  helm upgrade redis helmcoins --values=redis.yaml
  ```

]

---

## Deployment template

- If we look at the deployment template, we see this section:
  ```yaml
          ports:
            - name: http
              containerPort: 80
              protocol: TCP
  ```

- The container port is hard-coded to 80

- We'll change it to use the port number specified in the values

---

## Changing the deployment template

.exercise[  

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
