# Static pods

- Pods are usually created indirectly, through another resource:

  Deployment, Daemon Set, Job, Stateful Set ...

- They can also be created directly

- This can be done by writing YAML and using `kubectl apply` or `kubectl create`

- Some resources (not all of them) can be created with `kubectl run`

- Creating a resource with `kubectl` requires the API to be up

- If we want to run the API server (and its dependencies) on Kubernetes itself ...

  ... how can we create API pods (and other resources) when the API is not up yet?

---

## In theory

- Each component of the control plane can be replicated

- We could set up the control plane outside of the cluster

- Then, once the cluster is up, create replicas running on the cluster

- Finally, remove the replicas that are running outside of the cluster

*What could possibly go wrong?*

---

## Sawing off the branch you're sitting on

- What if anything goes wrong?

  (During the setup or at a later point)

- Worst case scenario, we might need to:

  - set up a new control plane (outside of the cluster)
  
  - restore a backup from the old control plane
  
  - move the new control plane to the cluster (again)

- This doesn't sound like a great experience

---

## Static pods to the rescue

- Pods are started by kubelet (an agent running on every node)

- To know which pods it should run, the kubelet queries the API server

- The kubelet can also get a list of *static pods* from:

  - a directory containing one (or multiple) *manifests*, and/or
  
  - a URL (serving a *manifest*)

- These "manifests" are basically YAML definitions

  (As produced by `kubectl get pod my-little-pod -o yaml --export`)

---

## Static pods are dynamic

- Kubelet will periodically reload the manifests

- It will start/stop pods accordingly

  (i.e. it is not necessary to restart the kubelet after updating the manifests)

- When connected to the Kubernetes API, the kubelet will create *mirror pods*

- Mirror pods are copies of the static pods

  (so they can be seen with e.g. `kubectl get pods`)

---

## Bootstrapping a cluster with static pods

- We can run control plane components with these static pods

- They don't need the API to be up (just the kubelet)

- Once they are up, the API becomes available

- These pods are then visible through the API

  (We cannot upgrade them from the API, though)

*This is how kubeadm has initialized our clusters.*

---

## Static pods vs normal pods

- The API only gives us a read-only access to static pods

- We can `kubectl delete` a static pod ...

  ... But the kubelet will restart it immediately

- Static pods can be selected just like other pods

  (So they can receive service traffic)

- A service can select a mixture of static and other pods

---

## From static pods to normal pods

- Once the control plane is up and running, it can be used to create normal pods

- We can then set up a copy of the control plane in normal pods

- Then the static pods can be removed

- The scheduler and the controller manager use leader election

  (Only one is active at a time; removing an instance is seamless)

- Each instance of the API server adds itself to the `kubernetes` service

- Etcd will typically require more work!

---

## From normal pods back to static pods

- Alright, but what if the control plane is down and we need to fix it?

- We restart it using static pods!

- This can be done automatically with the [Pod Checkpointer]

- The Pod Checkpointer automatically generates manifests of running pods

- The manifests are used to restart these pods if API contact is lost

  (More details in the [Pod Checkpointer] documentation page)

- This technique is used by [bootkube]

[Pod Checkpointer]: https://github.com/kubernetes-incubator/bootkube/blob/master/cmd/checkpoint/README.md
[bootkube]: https://github.com/kubernetes-incubator/bootkube

---

## Where should the control plane be?

*Is it better to run the control plane in static pods, or normal pods?*

- If I'm a *user* of the cluster: I don't care, it makes no difference to me

- What if I'm an *admin*, i.e. the person who installs, upgraes, repairs... the cluster?

- If I'm using a managed Kubernetes cluster (AKS, EKS, GKE...) it's not my problem

  (I'm not the one setting up and managing the control plane)

- If I already picked a tool (kubeadm, kops...) to setup my cluster, the tool decides for me

- What if I haven't picked a tool yet, or if I'm installing from scratch?

  - static pods = easier to set up, easier to troubleshoot, less risk of outage

  - normal pods = easier to upgrade, easier to move (if nodes need to be shutdown)

---

## Static pods in action

- On our clusters, the `staticPodPath` is `/etc/kubernetes/manifests`

.exercise[

- Have a look at this directory:
  ```bash
  ls -l /etc/kubernetes/manifests
  ```

]

We should see YAML files corresponding to the pods of the control plane.

---

## Running a static pod

- We are going to add a pod manifest to the directory, and kubelet will run it

.exercise[

- Copy a manifest to the directory:
  ```bash
  sudo cp ~/container.training/k8s/just-a-pod.yaml /etc/kubernetes/manifests
  ```

- Check that it's running:
  ```bash
  kubectl get pods
  ```

]

The output should include a pod named `hello-node1`.

---

## Remarks

In the manifest, the pod was named `hello`.

```yaml
apiVersion: v1
Kind: Pod
metadata:
  name: hello
  namespace: default
spec:
  containers:
  - name: hello
    image: nginx
```

The `-node1` suffix was added automatically by kubelet.

If we delete the pod (with `kubectl delete`), it will be recreated immediately.

To delete the pod, we need to delete (or move) the manifest file.
