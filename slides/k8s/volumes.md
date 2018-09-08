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

## Kubernetes volumes vs. Docker volumes

- Kubernetes and Docker volumes are very similar

  (the [Kubernetes documentation](https://kubernetes.io/docs/concepts/storage/volumes/) says otherwise ...
  <br/>
  but it refers to Docker 1.7, which was released in 2015!)

- Docker volumes allow to share data between containers running on the same host

- Kubernetes volumes allow us to share data between containers in the same pod

- Both Docker and Kubernetes volumes allow us access to storage systems

- Kubernetes volumes are also used to expose configuration and secrets

- Docker has specific concepts for configuration and secrets

  (but under the hood, the technical implementation is similar)

- If you're not familiar with Docker volumes, you can safely ignore this slide!

---

## A simple volume example

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

## A simple volume example, explained

- We define a standalone `Pod` named `nginx-with-volume`

- In that pod, there is a volume named `www`

- No type is specified, so it will default to `emptyDir`

  (as the name implies, it will be initialized as an empty directory at pod creation)

- In that pod, there is also a container named `nginx`

- That container mounts the volume `www` to path `/usr/share/nginx/html/`

---

## A volume shared between two containers

.small[
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
  - name: git
    image: alpine
    command: [ "sh", "-c", "apk add --no-cache git && git clone https://github.com/octocat/Spoon-Knife /www" ]
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

## Sharing a volume, in action

- Let's try it!

.exercise[

- Create the pod by applying the YAML file:
  ```bash
  kubectl apply -f ~/container.training/k8s/nginx-with-volume.yaml
  ```

- Check the IP address that was allocated to our pod:
  ```bash
  kubectl get pod nginx-with-volume -o wide
  IP=$(kubectl get pod nginx-with-volume -o json | jq -r .status.podIP)
  ```

- Access the web server:
  ```bash
  curl $IP
  ```

]

---

## The devil is in the details

- The default `restartPolicy` is `Always`

- This would cause our `git` container to run again ... and again ... and again

  (with an exponential back-off delay, as explained [in the documentation](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#restart-policy))

- That's why we specified `restartPolicy: OnFailure`

- There is a short period of time during which the website is not available

  (because the `git` container hasn't done its job yet)

- This could be avoided by using [Init Containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)

  (we will see a live example in a few sections)

---

## Volume lifecycle

- The lifecycle of a volume is linked to the pod's lifecycle

- This means that a volume is created when the pod is created

- This is mostly relevant for `emptyDir` volumes

  (other volumes, like remote storage, are not "created" but rather "attached" )

- A volume survives across container restarts

- A volume is destroyed (or, for remote storage, detached) when the pod is destroyed
