# Authoring YAML

- We have already generated YAML implicitly, with e.g.:

  - `kubectl run`

  - `kubectl create deployment` (and a few other `kubectl create` variants)

  - `kubectl expose`

- When and why do we need to write our own YAML?

- How do we write YAML from scratch?

---

## The limits of generated YAML

- Many advanced (and even not-so-advanced) features require to write YAML:

  - pods with multiple containers

  - resource limits

  - healthchecks

  - DaemonSets, StatefulSets

  - and more!

- How do we access these features?

---

## Various ways to write YAML

- Completely from scratch with our favorite editor

  (yeah, right)

- Dump an existing resource with `kubectl get -o yaml ...`

  (it is recommended to clean up the result)

- Ask `kubectl` to generate the YAML

  (with a `kubectl create --dry-run=client -o yaml`)

- Use The Docs, Luke

  (the documentation almost always has YAML examples)

---

## Generating YAML from scratch

- Start with a namespace:
  ```yaml
    kind: Namespace
    apiVersion: v1
    metadata:
      name: hello
  ```

- We can use `kubectl explain` to see resource definitions:
  ```bash
  kubectl explain -r pod.spec
  ```

- Not the easiest option!

---

## Dump the YAML for an existing resource

- `kubectl get -o yaml` works!

- A lot of fields in `metadata` are not necessary

  (`managedFields`, `resourceVersion`, `uid`, `creationTimestamp` ...)

- Most objects will have a `status` field that is not necessary

- Default or empty values can also be removed for clarity

- This can be done manually or with the `kubectl-neat` plugin

  `kubectl get -o yaml ... | kubectl neat`

---

## Generating YAML without creating resources

- We can use the `--dry-run=client` option

.lab[

- Generate the YAML for a Deployment without creating it:
  ```bash
  kubectl create deployment web --image nginx --dry-run=client
  ```

- Optionally clean it up with `kubectl neat`, too

]

---

class: extra-details

## Using `--dry-run` with `kubectl apply`

- The `--dry-run` option can also be used with `kubectl apply`

- However, it can be misleading (it doesn't do a "real" dry run)

- Let's see what happens in the following scenario:

  - generate the YAML for a Deployment

  - tweak the YAML to transform it into a DaemonSet

  - apply that YAML to see what would actually be created

---

class: extra-details

## The limits of `kubectl apply --dry-run=client`

.lab[

- Generate the YAML for a deployment:
  ```bash
  kubectl create deployment web --image=nginx -o yaml > web.yaml
  ```

- Change the `kind` in the YAML to make it a `DaemonSet`:
  ```bash
  sed -i s/Deployment/DaemonSet/ web.yaml
  ```

- Ask `kubectl` what would be applied:
  ```bash
  kubectl apply -f web.yaml --dry-run=client --validate=false -o yaml
  ```

]

The resulting YAML doesn't represent a valid DaemonSet.

---

class: extra-details

## Server-side dry run

- Since Kubernetes 1.13, we can use [server-side dry run and diffs](https://kubernetes.io/blog/2019/01/14/apiserver-dry-run-and-kubectl-diff/)

- Server-side dry run will do all the work, but *not* persist to etcd

  (all validation and mutation hooks will be executed)

.lab[

- Try the same YAML file as earlier, with server-side dry run:
  ```bash
  kubectl apply -f web.yaml --dry-run=server --validate=false -o yaml
  ```

]

The resulting YAML doesn't have the `replicas` field anymore.

Instead, it has the fields expected in a DaemonSet.

---

class: extra-details

## Advantages of server-side dry run

- The YAML is verified much more extensively

- The only step that is skipped is "write to etcd"

- YAML that passes server-side dry run *should* apply successfully

  (unless the cluster state changes by the time the YAML is actually applied)

- Validating or mutating hooks that have side effects can also be an issue

---

class: extra-details

## `kubectl diff`

- Kubernetes 1.13 also introduced `kubectl diff`

- `kubectl diff` does a server-side dry run, *and* shows differences

.lab[

- Try `kubectl diff` on the YAML that we tweaked earlier:
  ```bash
  kubectl diff -f web.yaml
  ```

<!-- ```wait status:``` -->

]

Note: we don't need to specify `--validate=false` here.

---

## Advantage of YAML

- Using YAML (instead of `kubectl create <kind>`) allows to be *declarative*

- The YAML describes the desired state of our cluster and applications

- YAML can be stored, versioned, archived (e.g. in git repositories)

- To change resources, change the YAML files

  (instead of using `kubectl edit`/`scale`/`label`/etc.)

- Changes can be reviewed before being applied

  (with code reviews, pull requests ...)

- This workflow is sometimes called "GitOps"

  (there are tools like Weave Flux or GitKube to facilitate it)

---

## YAML in practice

- Get started with `kubectl create deployment` and `kubectl expose`

  (until you have something that works)

- Then, run these commands again, but with `-o yaml --dry-run=client`

  (to generate and save YAML manifests)

- Try to apply these manifests in a clean environment

  (e.g. a new Namespace)

- Check that everything works; tweak and iterate if needed

- Commit the YAML to a repo 💯🏆️

---

## "Day 2" YAML

- Don't hesitate to remove unused fields

  (e.g. `creationTimestamp: null`, most `{}` values...)

- Check your YAML with:

  [kube-score](https://github.com/zegl/kube-score) (installable with krew)

  [kube-linter](https://github.com/stackrox/kube-linter)

- Check live resources with tools like [popeye](https://popeyecli.io/)

- Remember that like all linters, they need to be configured for your needs!

???

:EN:- Techniques to write YAML manifests
:FR:- Comment écrire des *manifests* YAML
