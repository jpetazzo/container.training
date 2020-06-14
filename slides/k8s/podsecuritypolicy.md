# Pod Security Policies

- By default, our pods and containers can do *everything*

  (including taking over the entire cluster)

- We are going to show an example of a malicious pod

- Then we will explain how to avoid this with PodSecurityPolicies

- We will enable PodSecurityPolicies on our cluster

- We will create a couple of policies (restricted and permissive)

- Finally we will see how to use them to improve security on our cluster

---

## Setting up a namespace

- For simplicity, let's work in a separate namespace

- Let's create a new namespace called "green"

.exercise[

- Create the "green" namespace:
  ```bash
  kubectl create namespace green
  ```

- Change to that namespace:
  ```bash
  kns green
  ```

]

---

## Creating a basic Deployment

- Just to check that everything works correctly, deploy NGINX

.exercise[

- Create a Deployment using the official NGINX image:
  ```bash
  kubectl create deployment web --image=nginx
  ```

- Confirm that the Deployment, ReplicaSet, and Pod exist, and that the Pod is running:
  ```bash
  kubectl get all
  ```

]

---

## One example of malicious pods

- We will now show an escalation technique in action

- We will deploy a DaemonSet that adds our SSH key to the root account

  (on *each* node of the cluster)

- The Pods of the DaemonSet will do so by mounting `/root` from the host

.exercise[

- Check the file `k8s/hacktheplanet.yaml` with a text editor:
  ```bash
  vim ~/container.training/k8s/hacktheplanet.yaml
  ```

- If you would like, change the SSH key (by changing the GitHub user name)

]

---

## Deploying the malicious pods

- Let's deploy our "exploit"!

.exercise[

- Create the DaemonSet:
  ```bash
  kubectl create -f ~/container.training/k8s/hacktheplanet.yaml
  ```

- Check that the pods are running:
  ```bash
  kubectl get pods
  ```

- Confirm that the SSH key was added to the node's root account:
  ```bash
  sudo cat /root/.ssh/authorized_keys
  ```

]

---

## Cleaning up

- Before setting up our PodSecurityPolicies, clean up that namespace

.exercise[

- Remove the DaemonSet:
  ```bash
  kubectl delete daemonset hacktheplanet
  ```

- Remove the Deployment:
  ```bash
  kubectl delete deployment web
  ```

]

---

## Pod Security Policies in theory

- To use PSPs, we need to activate their specific *admission controller*

- That admission controller will intercept each pod creation attempt

- It will look at:

  - *who/what* is creating the pod

  - which PodSecurityPolicies they can use

  - which PodSecurityPolicies can be used by the Pod's ServiceAccount

- Then it will compare the Pod with each PodSecurityPolicy one by one

- If a PodSecurityPolicy accepts all the parameters of the Pod, it is created

- Otherwise, the Pod creation is denied and it won't even show up in `kubectl get pods`

---

## Pod Security Policies fine print

- With RBAC, using a PSP corresponds to the verb `use` on the PSP

  (that makes sense, right?)

- If no PSP is defined, no Pod can be created

  (even by cluster admins)

- Pods that are already running are *not* affected

- If we create a Pod directly, it can use a PSP to which *we* have access

- If the Pod is created by e.g. a ReplicaSet or DaemonSet, it's different:

  - the ReplicaSet / DaemonSet controllers don't have access to *our* policies

  - therefore, we need to give access to the PSP to the Pod's ServiceAccount

---

## Pod Security Policies in practice

- We are going to enable the PodSecurityPolicy admission controller

- At that point, we won't be able to create any more pods (!)

- Then we will create a couple of PodSecurityPolicies

- ...And associated ClusterRoles (giving `use` access to the policies)

- Then we will create RoleBindings to grant these roles to ServiceAccounts

- We will verify that we can't run our "exploit" anymore

---

## Enabling Pod Security Policies

- To enable Pod Security Policies, we need to enable their *admission plugin*

- This is done by adding a flag to the API server

- On clusters deployed with `kubeadm`, the control plane runs in static pods

- These pods are defined in YAML files located in `/etc/kubernetes/manifests`

- Kubelet watches this directory

- Each time a file is added/removed there, kubelet creates/deletes the corresponding pod

- Updating a file causes the pod to be deleted and recreated

---

## Updating the API server flags

- Let's edit the manifest for the API server pod

.exercise[

- Have a look at the static pods:
  ```bash
  ls -l /etc/kubernetes/manifests
  ```

- Edit the one corresponding to the API server:
  ```bash
  sudo vim /etc/kubernetes/manifests/kube-apiserver.yaml
  ```

<!-- ```wait apiVersion``` -->

]

---

## Adding the PSP admission plugin

- There should already be a line with `--enable-admission-plugins=...`

- Let's add `PodSecurityPolicy` on that line

.exercise[

- Locate the line with `--enable-admission-plugins=`

- Add `PodSecurityPolicy`

  It should read: `--enable-admission-plugins=NodeRestriction,PodSecurityPolicy`

- Save, quit

<!--
```keys /--enable-admission-plugins=```
```key ^J```
```key $```
```keys a,PodSecurityPolicy```
```key Escape```
```keys :wq```
```key ^J```
-->

]

---

## Waiting for the API server to restart

- The kubelet detects that the file was modified

- It kills the API server pod, and starts a new one

- During that time, the API server is unavailable

.exercise[

- Wait until the API server is available again

]

---

## Check that the admission plugin is active

- Normally, we can't create any Pod at this point

.exercise[

- Try to create a Pod directly:
  ```bash
  kubectl run testpsp1 --image=nginx --restart=Never
  ```

<!-- ```wait forbidden: no providers available``` -->

- Try to create a Deployment:
  ```bash
  kubectl create deployment testpsp2 --image=nginx
  ```

- Look at existing resources:
  ```bash
  kubectl get all
  ```

]

We can get hints at what's happening by looking at the ReplicaSet and Events.

---

## Introducing our Pod Security Policies

- We will create two policies:

  - privileged (allows everything)

  - restricted (blocks some unsafe mechanisms)

- For each policy, we also need an associated ClusterRole granting *use*

---

## Creating our Pod Security Policies

- We have a couple of files, each defining a PSP and associated ClusterRole:

  - k8s/psp-privileged.yaml: policy `privileged`, role `psp:privileged`
  - k8s/psp-restricted.yaml: policy `restricted`, role `psp:restricted`

.exercise[

- Create both policies and their associated ClusterRoles:
  ```bash
  kubectl create -f ~/container.training/k8s/psp-restricted.yaml
  kubectl create -f ~/container.training/k8s/psp-privileged.yaml
  ```
]

- The privileged policy comes from [the Kubernetes documentation](https://kubernetes.io/docs/concepts/policy/pod-security-policy/#example-policies)

- The restricted policy is inspired by that same documentation page

---

## Check that we can create Pods again

- We haven't bound the policy to any user yet

- But `cluster-admin` can implicitly `use` all policies

.exercise[

- Check that we can now create a Pod directly:
  ```bash
  kubectl run testpsp3 --image=nginx --restart=Never
  ```

- Create a Deployment as well:
  ```bash
  kubectl create deployment testpsp4 --image=nginx
  ```

- Confirm that the Deployment is *not* creating any Pods:
  ```bash
  kubectl get all
  ```

]

---

## What's going on?

- We can create Pods directly (thanks to our root-like permissions)

- The Pods corresponding to a Deployment are created by the ReplicaSet controller

- The ReplicaSet controller does *not* have root-like permissions

- We need to either:

  - grant permissions to the ReplicaSet controller

  *or*

  - grant permissions to our Pods' ServiceAccount

- The first option would allow *anyone* to create pods

- The second option will allow us to scope the permissions better

---

## Binding the restricted policy

- Let's bind the role `psp:restricted` to ServiceAccount `green:default`

  (aka the default ServiceAccount in the green Namespace)

- This will allow Pod creation in the green Namespace

  (because these Pods will be using that ServiceAccount automatically)

.exercise[

- Create the following RoleBinding:
  ```bash
    kubectl create rolebinding psp:restricted \
            --clusterrole=psp:restricted \
            --serviceaccount=green:default
  ```

]

---

## Trying it out

- The Deployments that we created earlier will *eventually* recover

  (the ReplicaSet controller will retry to create Pods once in a while)

- If we create a new Deployment now, it should work immediately

.exercise[

- Create a simple Deployment:
  ```bash
  kubectl create deployment testpsp5 --image=nginx
  ```

- Look at the Pods that have been created:
  ```bash
  kubectl get all
  ```

]

---

## Trying to hack the cluster

- Let's create the same DaemonSet we used earlier

.exercise[

- Create a hostile DaemonSet:
  ```bash
  kubectl create -f ~/container.training/k8s/hacktheplanet.yaml
  ```

- Look at the state of the namespace:
  ```bash
  kubectl get all
  ```

]

---

class: extra-details

## What's in our restricted policy?

- The restricted PSP is similar to the one provided in the docs, but:

  - it allows containers to run as root

  - it doesn't drop capabilities

- Many containers run as root by default, and would require additional tweaks

- Many containers use e.g. `chown`, which requires a specific capability

  (that's the case for the NGINX official image, for instance)

- We still block: hostPath, privileged containers, and much more!

---

class: extra-details

## The case of static pods

- If we list the pods in the `kube-system` namespace, `kube-apiserver` is missing

- However, the API server is obviously running

  (otherwise, `kubectl get pods --namespace=kube-system` wouldn't work)

- The API server Pod is created directly by kubelet

  (without going through the PSP admission plugin)

- Then, kubelet creates a "mirror pod" representing that Pod in etcd

- That "mirror pod" creation goes through the PSP admission plugin

- And it gets blocked!

- This can be fixed by binding `psp:privileged` to group `system:nodes`

---

## .warning[Before moving on...]

- Our cluster is currently broken

  (we can't create pods in namespaces kube-system, default, ...)

- We need to either:

  - disable the PSP admission plugin

  - allow use of PSP to relevant users and groups

- For instance, we could:

  - bind `psp:restricted` to the group `system:authenticated`

  - bind `psp:privileged` to the ServiceAccount `kube-system:default`

---

## Fixing the cluster

- Let's disable the PSP admission plugin

.exercise[

- Edit the Kubernetes API server static pod manifest

- Remove the PSP admission plugin

- This can be done with this one-liner:
  ```bash
  sudo sed -i s/,PodSecurityPolicy// /etc/kubernetes/manifests/kube-apiserver.yaml
  ```

]

???

:EN:- Preventing privilege escalation with Pod Security Policies
:FR:- Limiter les droits des conteneurs avec les *Pod Security Policies*
