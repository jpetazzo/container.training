# Pod Security Policies

- By default, our pods and containers can do *everything*

  (including taking over the entire cluster)

- We are going to show an example of a malicious pod

- Then we will explain how to avoid this with PodSecurityPolicies

- We will illustrate this by creating a non-privileged user limited to a namespace

---

## Setting up a namespace

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

## Using limited credentials

- When a namespace is created, a `default` ServiceAccount is added

- By default, this ServiceAccount doesn't have any access rights

- We will use this ServiceAccount as our non-privileged user

- We will obtain this ServiceAccount's token and add it to a context

- Then we will give basic access rights to this ServiceAccount

---

## Obtaining the ServiceAccount's token

- The token is stored in a Secret

- The Secret is listed in the ServiceAccount

.exercise[

- Obtain the name of the Secret from the ServiceAccount::
  ```bash
  SECRET=$(kubectl get sa default -o jsonpath={.secrets[0].name})
  ```

- Extract the token from the Secret object:
  ```bash
  TOKEN=$(kubectl get secrets $SECRET -o jsonpath={.data.token}
          | base64 -d)
  ```

]

---

class: extra-details

## Inspecting a Kubernetes token

- Kubernetes tokens are JSON Web Tokens

  (as defined by [RFC 7519](https://tools.ietf.org/html/rfc7519))

- We can view their content (and even verify them) easily

.exercise[

- Display the token that we obtained:
  ```bash
  echo $TOKEN
  ```

- Copy paste the token in the verification form on https://jwt.io

]

---

## Authenticating using the ServiceAccount token

- Let's create a new *context* accessing our cluster with that token

.exercise[

- First, add the token credentials to our kubeconfig file:
  ```bash
  kubectl config set-credentials green --token=$TOKEN
  ```

- Then, create a new context using these credentials:
  ```bash
  kubectl config set-context green --user=green --cluster=kubernetes
  ```

- Check the results:
  ```bash
  kubectl config get-contexts
  ```

]

---

## Using the new context

- Normally, this context doesn't let us access *anything* (yet)

.exercise[

- Change to the new context with one of these two commands:
  ```bash
  kctx green
  kubectl config use-context green
  ```

- Also change to the green namespace in that context:
  ```bash
  kns green
  ```

- Confirm that we don't have access to anything:
  ```bash
  kubectl get all
  ```

]

---

## Giving basic access rights

- Let's bind the ClusterRole `edit` to our ServiceAccount

- To allow access only to the namespace, we use a RoleBinding

  (instead of a ClusterRoleBinding, which would give global access)

.exercise[

- Switch back to `cluster-admin`:
  ```bash
  kctx -
  ```

- Create the Role Binding:
  ```bash
  kubectl create rolebinding green --clusterrole=edit --serviceaccount=green:default
  ```

]

---

## Verifying access rights

- Let's switch back to the `green` context and check that we have rights

.exercise[

- Switch back to `green`:
  ```bash
  kctx green
  ```

- Check our permissions:
  ```bash
  kubectl get all
  ```

]

We should see an empty list.

(Better than a series of permission errors!)

---

## Creating a basic Deployment

- Just to demonstrate that everything works correctly, deploy NGINX

.exercise[

- Create a Deployment using the official NGINX image:
  ```bash
  kubectl create deployment web --image=nginx
  ```

- Confirm that the Deployment, ReplicaSet, and Pod exist, and Pod is running:
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

- ... And associated ClusterRoles (giving `use` access to the policies)

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
  ls -l /etc/kubernetes/manifest
  ```

- Edit the one corresponding to the API server:
  ```bash
  sudo vim /etc/kubernetes/manifests/kube-apiserver.yaml
  ```

]

---

## Adding the PSP admission plugin

- There should already be a line with `--enable-admission-plugins=...`

- Let's add `PodSecurityPolicy` on that line

.exercise[

- Locate the line with `--enable-admission-plugins=`

- Add `PodSecurityPolicy`

  (It should read `--enable-admission-plugins=NodeRestriction,PodSecurityPolicy`)

- Save, quit

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

- Try to create a Deployment:
  ```bash
  kubectl run testpsp2 --image=nginx
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

## Binding the restricted policy

- Let's bind the role `psp:restricted` to ServiceAccount `green:default`

  (aka the default ServiceAccount in the green Namespace)

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

- Let's switch to the `green` context, and try to create resources

.exercise[

- Switch to the `green` context:
  ```bash
  kctx green
  ```

- Create a simple Deployment:
  ```bash
  kubectl create deployment web --image=nginx
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

  (we can't create pods in kube-system, default, ...)

- We need to either:

  - disable the PSP admission plugin

  - allow use of PSP to relevant users and groups

- For instance, we could:

  - bind `psp:restricted` to the group `system:authenticated`

  - bind `psp:privileged` to the ServiceAccount `kube-system:default`
