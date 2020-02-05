# Volumes

- Volumes are special directories that are mounted in containers

- Volumes can have many different purposes:

  - share files and directories between containers running on the same machine

  - share files and directories between containers and their host

  - centralize configuration information in Kubernetes and expose it to containers

  - manage credentials and secrets and expose them securely to containers

  - store persistent data for stateful services

  - access storage systems (like Ceph, EBS, NFS, Portworx, and many others)

---

class: extra-details

## Kubernetes volumes vs. Docker volumes

- Kubernetes and Docker volumes are very similar

  (the [Kubernetes documentation](https://kubernetes.io/docs/concepts/storage/volumes/) says otherwise ...
  <br/>
  but it refers to Docker 1.7, which was released in 2015!)

- Docker volumes allow us to share data between containers running on the same host

- Kubernetes volumes allow us to share data between containers in the same pod

- Both Docker and Kubernetes volumes enable access to storage systems

- Kubernetes volumes are also used to expose configuration and secrets

- Docker has specific concepts for configuration and secrets
  <br/>
  (but under the hood, the technical implementation is similar)

- If you're not familiar with Docker volumes, you can safely ignore this slide!

---

## Volumes ≠ Persistent Volumes

- Volumes and Persistent Volumes are related, but very different!

- *Volumes*:

  - appear in Pod specifications (we'll see that in a few slides)

  - do not exist as API resources (**cannot** do `kubectl get volumes`)

- *Persistent Volumes*:

  - are API resources (**can** do `kubectl get persistentvolumes`)

  - correspond to concrete volumes (e.g. on a SAN, EBS, etc.)

  - cannot be associated with a Pod directly; but through a Persistent Volume Claim

  - won't be discussed further in this section

---

## Adding a volume to a Pod

- We will start with the simplest Pod manifest we can find

- We will add a volume to that Pod manifest

- We will mount that volume in a container in the Pod

- By default, this volume will be an `emptyDir`

  (an empty directory)

- It will "shadow" the directory where it's mounted

---

## Our basic Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-without-volume
spec:
  containers:
  - name: nginx
    image: nginx
```

This is a MVP! (Minimum Viable Pod😉)

It runs a single NGINX container.

---

## Trying the basic pod

.exercise[

- Create the Pod:
  ```bash
  kubectl create -f ~/container.training/k8s/nginx-1-without-volume.yaml
  ```

<!-- ```bash kubectl wait pod/nginx-without-volume --for condition=ready ``` -->

- Get its IP address:
  ```bash
  IPADDR=$(kubectl get pod nginx-without-volume -o jsonpath={.status.podIP})
  ```

- Send a request with curl:
  ```bash
  curl $IPADDR
  ```

]

(We should see the "Welcome to NGINX" page.)

---

## Adding a volume

- We need to add the volume in two places:

  - at the Pod level (to declare the volume)

  - at the container level (to mount the volume)

- We will declare a volume named `www`

- No type is specified, so it will default to `emptyDir`

  (as the name implies, it will be initialized as an empty directory at pod creation)

- In that pod, there is also a container named `nginx`

- That container mounts the volume `www` to path `/usr/share/nginx/html/`

---

## The Pod with a volume

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-with-volume
spec:
  volumes:
  - name: www
  containers:
  - name: nginx
    image: nginx
    volumeMounts:
    - name: www
      mountPath: /usr/share/nginx/html/
```

---

## Trying the Pod with a volume

.exercise[

- Create the Pod:
  ```bash
  kubectl create -f ~/container.training/k8s/nginx-2-with-volume.yaml
  ```

<!-- ```bash kubectl wait pod/nginx-with-volume --for condition=ready ``` -->

- Get its IP address:
  ```bash
  IPADDR=$(kubectl get pod nginx-with-volume -o jsonpath={.status.podIP})
  ```

- Send a request with curl:
  ```bash
  curl $IPADDR
  ```

]

(We should now see a "403 Forbidden" error page.)

---

## Populating the volume with another container

- Let's add another container to the Pod

- Let's mount the volume in *both* containers

- That container will populate the volume with static files

- NGINX will then serve these static files

- To populate the volume, we will clone the Spoon-Knife repository

  - this repository is https://github.com/octocat/Spoon-Knife

  - it's very popular (more than 100K stars!)

---

## Sharing a volume between two containers

.small[
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-with-git
spec:
  volumes:
  - name: www
  containers:
  - name: nginx
    image: nginx
    volumeMounts:
    - name: www
      mountPath: /usr/share/nginx/html/
  - name: git
    image: alpine
    command: [ "sh", "-c", "apk add git && git clone https://github.com/octocat/Spoon-Knife /www" ]
    volumeMounts:
    - name: www
      mountPath: /www/
  restartPolicy: OnFailure
```
]

---

## Sharing a volume, explained

- We added another container to the pod

- That container mounts the `www` volume on a different path (`/www`)

- It uses the `alpine` image

- When started, it installs `git` and clones the `octocat/Spoon-Knife` repository

  (that repository contains a tiny HTML website)

- As a result, NGINX now serves this website

---

## Trying the shared volume

- This one will be time-sensitive!

- We need to catch the Pod IP address *as soon as it's created*

- Then send a request to it *as fast as possible*

.exercise[

- Watch the pods (so that we can catch the Pod IP address)
  ```bash
  kubectl get pods -o wide --watch
  ```

<!--
```wait NAME```
```tmux split-pane -v```
-->

]

---

## Shared volume in action

.exercise[

- Create the pod:
  ```bash
  kubectl create -f ~/container.training/k8s/nginx-3-with-git.yaml
  ```

<!--
```bash kubectl wait pod/nginx-with-git --for condition=initialized```
```bash IP=$(kubectl get pod nginx-with-git -o jsonpath={.status.podIP})```
-->

- As soon as we see its IP address, access it:
  ```bash
  curl `$IP`
  ```

<!-- ```bash /bin/sleep 5``` -->

- A few seconds later, the state of the pod will change; access it again:
  ```bash
  curl `$IP`
  ```

]

The first time, we should see "403 Forbidden".

The second time, we should see the HTML file from the Spoon-Knife repository.

---

## Explanations

- Both containers are started at the same time

- NGINX starts very quickly

  (it can serve requests immediately)

- But at this point, the volume is empty

  (NGINX serves "403 Forbidden")

- The other containers installs git and clones the repository

  (this takes a bit longer)

- When the other container is done, the volume holds the repository

  (NGINX serves the HTML file)

---

## The devil is in the details

- The default `restartPolicy` is `Always`

- This would cause our `git` container to run again ... and again ... and again

  (with an exponential back-off delay, as explained [in the documentation](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#restart-policy))

- That's why we specified `restartPolicy: OnFailure`

---

## Inconsistencies

- There is a short period of time during which the website is not available

  (because the `git` container hasn't done its job yet)

- With a bigger website, we could get inconsistent results

  (where only a part of the content is ready)

- In real applications, this could cause incorrect results

- How can we avoid that?

---

## Init Containers

- We can define containers that should execute *before* the main ones

- They will be executed in order

  (instead of in parallel)

- They must all succeed before the main containers are started

- This is *exactly* what we need here!

- Let's see one in action

.footnote[See [Init Containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/) documentation for all the details.]

---

## Defining Init Containers

.small[
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-with-init
spec:
  volumes:
  - name: www
  containers:
  - name: nginx
    image: nginx
    volumeMounts:
    - name: www
      mountPath: /usr/share/nginx/html/
  initContainers:
  - name: git
    image: alpine
    command: [ "sh", "-c", "apk add --no-cache git && git clone https://github.com/octocat/Spoon-Knife /www" ]
    volumeMounts:
    - name: www
      mountPath: /www/
```
]

---

## Trying the init container

.exercise[

- Repeat the same operation as earlier

  (try to send HTTP requests as soon as the pod comes up)

<!--
```key ^D```
```key ^C```
-->

]

- This time, instead of "403 Forbidden" we get a "connection refused"

- NGINX doesn't start until the git container has done its job

- We never get inconsistent results

  (a "half-ready" container)

---

## Other uses of init containers

- Load content

- Generate configuration (or certificates)

- Database migrations

- Waiting for other services to be up

  (to avoid flurry of connection errors in main container)

- etc.

---

## Volume lifecycle

- The lifecycle of a volume is linked to the pod's lifecycle

- This means that a volume is created when the pod is created

- This is mostly relevant for `emptyDir` volumes

  (other volumes, like remote storage, are not "created" but rather "attached" )

- A volume survives across container restarts

- A volume is destroyed (or, for remote storage, detached) when the pod is destroyed
