# Restricting Pod Permissions

- By default, our pods and containers can do *everything*

  (including taking over the entire cluster)

- We are going to show an example of a malicious pod

  (which will give us root access to the whole cluster)

- Then we will explain how to avoid this with admission control

  (PodSecurityAdmission, PodSecurityPolicy, or external policy engine)

---

## Setting up a namespace

- For simplicity, let's work in a separate namespace

- Let's create a new namespace called "green"

.lab[

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

.lab[

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

.lab[

- Check the file `k8s/hacktheplanet.yaml` with a text editor:
  ```bash
  vim ~/container.training/k8s/hacktheplanet.yaml
  ```

- If you would like, change the SSH key (by changing the GitHub user name)

]

---

## Deploying the malicious pods

- Let's deploy our "exploit"!

.lab[

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

## Mitigations

- This can be avoided with *admission control*

- Admission control = filter for (write) API requests

- Admission control can use:

  - plugins (compiled in API server; enabled/disabled by reconfiguration)

  - webhooks (registesred dynamically)

- Admission control has many other uses

  (enforcing quotas, adding ServiceAccounts automatically, etc.)

---

## Admission plugins

- [PodSecurityPolicy](https://kubernetes.io/docs/concepts/policy/pod-security-policy/) (will be removed in Kubernetes 1.25)

  - create PodSecurityPolicy resources

  - create Role that can `use` a PodSecurityPolicy

  - create RoleBinding that grants the Role to a user or ServiceAccount

- [PodSecurityAdmission](https://kubernetes.io/docs/concepts/security/pod-security-admission/) (alpha since Kubernetes 1.22)

  - use pre-defined policies (privileged, baseline, restricted)

  - label namespaces to indicate which policies they can use

  - optionally, define default rules (in the absence of labels)

---

## Dynamic admission

- Leverage ValidatingWebhookConfigurations

  (to register a validating webhook)

- Examples:

  [Kubewarden](https://www.kubewarden.io/)

  [Kyverno](https://kyverno.io/policies/pod-security/)

  [OPA Gatekeeper](https://github.com/open-policy-agent/gatekeeper)

- Pros: available today; very flexible and customizable

- Cons: performance and reliability of external webhook

---

## Acronym salad

- PSP = Pod Security Policy

  - an admission plugin called PodSecurityPolicy

  - a resource named PodSecurityPolicy (`apiVersion: policy/v1beta1`)

- PSA = Pod Security Admission

  - an admission plugin called PodSecurity, enforcing PSS

- PSS = Pod Security Standards

  - a set of 3 policies (privileged, baseline, restricted)\

???

:EN:- Mechanisms to prevent pod privilege escalation
:FR:- Les mécanismes pour limiter les privilèges des pods
