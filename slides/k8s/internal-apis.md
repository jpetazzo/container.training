# Kubernetes Internal APIs

- Almost every Kubernetes component has some kind of internal API

  (some components even have multiple APIs on different ports!)

- At the very least, these can be used for healthchecks

  (you *should* leverage this if you are deploying and operating Kubernetes yourself!)

- Sometimes, they are used internally by Kubernetes

  (e.g. when the API server retrieves logs from kubelet)

- Let's review some of these APIs!

---

## API hunting guide

This is how we found and investigated these APIs:

- look for open ports on Kubernetes nodes

  (worker nodes or control plane nodes)

- check which process owns that port

- probe the port (with `curl` or other tools)

- read the source code of that process

  (in particular when looking for API routes)

OK, now let's see the results!

---

## etcd

- 2379/tcp → etcd clients

  - should be HTTPS and require mTLS authentication

- 2380/tcp → etcd peers

  - should be HTTPS and require mTLS authentication

- 2381/tcp → etcd healthcheck

  - HTTP without authentication

  - exposes two API routes: `/health` and `/metrics`

---

## kubelet

- 10248/tcp → healthcheck

  - HTTP without authentication

  - exposes a single API route, `/healthz`, that just returns `ok`

- 10250/tcp → internal API

  - should be HTTPS and require mTLS authentication

  - used by the API server to obtain logs, `kubectl exec`, etc.

---

class: extra-details

## kubelet API

- We can authenticate with e.g. our TLS admin certificate

- The following routes should be available:

  - `/healthz`
  - `/configz` (serves kubelet configuration)
  - `/metrics`
  - `/pods` (returns *desired state*)
  - `/runningpods` (returns *current state* from the container runtime)
  - `/logs` (serves files from `/var/log`)
  - `/containerLogs/<namespace>/<podname>/<containername>` (can add e.g. `?tail=10`)
  - `/run`, `/exec`, `/attach`, `/portForward`

- See [kubelet source code](https://github.com/kubernetes/kubernetes/blob/master/pkg/kubelet/server/server.go) for details!

---

class: extra-details

## Trying the kubelet API

The following example should work on a cluster deployed with `kubeadm`.

1. Obtain the key and certificate for the `cluster-admin` user.

2. Log into a node.

3. Copy the key and certificate on the node.

4. Find out the name of the `kube-proxy` pod running on that node.

5. Run the following command, updating the pod name:
   ```bash
   curl -d cmd=ls -k --cert admin.crt --key admin.key \
       https://localhost:10250/run/kube-system/`kube-proxy-xy123`/kube-proxy
   ```

... This should show the content of the root directory in the pod.

---

## kube-proxy

- 10249/tcp → healthcheck

  - HTTP, without authentication

  - exposes a few API routes: `/healthz` (just returns `ok`), `/configz`, `/metrics`

- 10256/tcp → another healthcheck

  - HTTP, without authentication

  - also exposes a `/healthz` API route (but this one shows a timestamp)

---

## kube-controller and kube-scheduler

- 10257/tcp → kube-controller

  - HTTPS, with optional mTLS authentication

  - `/healthz` doesn't require authentication

  - ... but `/configz` and `/metrics` do (use e.g. admin key and certificate)

- 10259/tcp → kube-scheduler

  - similar to kube-controller, with the same routes

???

:EN:- Kubernetes internal APIs
:FR:- Les APIs internes de Kubernetes