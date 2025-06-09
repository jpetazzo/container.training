# Exercise — static pods

- We want to run the control plane in static pods

  (etcd, API server, controller manager, scheduler)

- For Kubernetes components, we can use [these images](https://kubernetes.io/releases/download/#container-images)

- For etcd, we can use [this image](https://quay.io/repository/coreos/etcd?tab=tags)

- If we're using keys, certificates... We can use [hostPath volumes](https://kubernetes.io/docs/concepts/storage/volumes/#hostpath)

---

## Testing

After authoring our static pod manifests and placing them in the right directory,
we should be able to start our cluster simply by starting kubelet.

(Assuming that the container engine is already running.)

For bonus points: write and enable a systemd unit for kubelet!
