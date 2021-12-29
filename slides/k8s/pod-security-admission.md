# Pod Security Admission

- "New" policies

  (available in alpha since Kubernetes 1.22)

- Easier to use

  (doesn't require complex interaction bewteen policies and RBAC)

---

## PSA in theory

- Leans on PSS (Pod Security Standards)

- Defines three policies:

  - `privileged` (can do everything; for system components)

  - `restricted` (no root user; almost no capabilities)

  - `baseline` (in-between with reasonable defaults)

- Label namespaces to indicate which policies are allowed there

- Also supports setting global defaults

- Supports `enforce`, `audit`, and `warn` modes

---

## Pod Security Standards

- `privileged`

  - can do everything

- `baseline`

  - disables hostNetwork, hostPID, hostIPC, hostPorts, hostPath volumes
  - limits which SELinux/AppArmor profiles can be used
  - containers can still run as root and use most capabilities

- `restricted`

  - limits volumes to configMap, emptyDir, ephemeral, secret, PVC
  - containers can't run as root, only capability is NET_BIND_SERVICE
  - `baseline` (can't do privileged pods, hostPath, hostNetwork...)

---

class: extra-details

## Why `baseline` ≠ `restricted` ?

- `baseline` = should work for that vast majority of images

- `restricted` = better, but might break / require adaptation

- Many images run as root by default

- Some images use CAP_CHOWN (to `chown` files)

- Some programs use CAP_NET_RAW (e.g. `ping`)

---

## PSA in practice

- Step 1: enable the PodSecurity admission plugin

- Step 2: label some Namespaces

- Step 3: provide an AdmissionConfiguration (optional)

- Step 4: profit!

---

## Enabling PodSecurity

- This requires Kubernetes 1.22 or later
 
- This requires the ability to reconfigure the API server

- The following slides assume that we're using `kubeadm`

  (and have write access to `/etc/kubernetes/manifests`)

---

## Reconfiguring the API server

- In Kubernetes 1.22, we need to enable the `PodSecurity` feature gate

- In later versions, this might be enabled automatically

.lab[

- Edit `/etc/kubernetes/manifests/kube-apiserver.yaml`

- In the `command` list, add `--feature-gates=PodSecurity=true`

- Save, quit, wait for the API server to be back up again

]

Note: for bonus points, edit the `kubeadm-config` ConfigMap instead!

---

## Namespace labels

- Three optional labels can be added to namespaces:

  `pod-security.kubernetes.io/enforce`

  `pod-security.kubernetes.io/audit`

  `pod-security.kubernetes.io/warn`

- The values can be: `baseline`, `restricted`, `privileged`

  (setting it to `privileged` doesn't really do anything)

---

## `enforce`, `audit`, `warn`

- `enforce` = prevents creation of pods

- `warn` = allow creation but include a warning in the API response

  (will be visible e.g. in `kubectl` output)

- `audit` = allow creation but generate an API audit event

  (will be visible if API auditing has been enabled and configured)

---

## Blocking privileged pods

- Let's block `privileged` pods everywhere

- And issue warnings and audit for anything above the `restricted` level

.lab[

- Set up the default policy for all namespaces:
  ```bash
  kubectl label namespaces \
      pod-security.kubernetes.io/enforce=baseline \
      pod-security.kubernetes.io/audit=restricted \
      pod-security.kubernetes.io/warn=restricted \
      --all
  ```

]

Note: warnings will be issued for infringing pods, but they won't be affected yet.

---

class: extra-details

## Check before you apply

- When adding an `enforce` policy, we see warnings

  (for the pods that would infringe that policy)

- It's possible to do a `--dry-run=server` to see these warnings

  (without applying the label)

- It will only show warnings for `enforce` policies

  (not `warn` or `audit`)

---

## Relaxing `kube-system`

- We have many system components in `kube-system`

- These pods aren't affected yet, but if there is a rolling update or something like that, the new pods won't be able to come up

.lab[

- Let's allow `privileged` pods in `kube-system`:
  ```bash
  kubectl label namespace kube-system \
      pod-security.kubernetes.io/enforce=privileged \
      pod-security.kubernetes.io/audit=privileged \
      pod-security.kubernetes.io/warn=privileged \
      --overwrite
  ```

]

---

## What about new namespaces?

- If new namespaces are created, they will get default permissions

- We can change that be using an *admission configuration*

- Step 1: write an "admission configuration file"

- Step 2: make sure that file is readable by the API server

- Step 3: add a flag to the API server to read that file

---

## Admission Configuration

Let's use @@LINK[k8s/admission-configuration.yaml]:

```yaml
@@INCLUDE[k8s/admission-configuration.yaml]
```

---

## Copy the file to the API server

- We need the file to be available from the API server pod

- For convenience, let's copy it do `/etc/kubernetes/pki`

  (it's definitely where it *should* be, but that'll do!)


.lab[

- Copy the file:
  ```bash
    sudo cp ~/container.training/k8s/admission-configuration.yaml \
            /etc/kubernetes/pki
  ```

]

---

## Reconfigure the API server

- We need to add a flag to the API server to use that file

.lab[

- Edit `/etc/kubernetes/manifests/kube-apiserver.yaml`

- In the list of `command` parameters, add:

  `--admission-control-config-file=/etc/kubernetes/pki/admission-configuration.yaml`

- Wait until the API server comes back online

]

---

## Test the new default policy

- Create a new Namespace

- Try to create the "hacktheplanet" DaemonSet in the new namespace

- We get a warning when creating the DaemonSet

- The DaemonSet is created

- But the Pods don't get created

---

## Clean up

- We probably want to remove the API server flags that we added

  (the feature gate and the admission configuration)

???

:EN:- Preventing privilege escalation with Pod Security Admission
:FR:- Limiter les droits des conteneurs avec *Pod Security Admission*
