# Exercise — This Namespace will self-destruct...

*What we want to do:*

Destroy a Namespace at a specific date and time.

*How we want to do it:*

With a CronJob that will fire at that specific date and time.

The CronJob will create a Pod that will delete the namespace.

(This can be done with `kubectl delete namespace`, which requires installing the `kubectl` binary or finding an image that already has it; or, if you feel brave, with a direct Kubernetes API request with `curl` or a similar tool.)

The Pod will need sufficient Kubernetes permissions to do that task.

---

## Multiple levels

- Level 1: put our `kubeconfig` file in a Secret

- Level 2: leverage RBAC to give the Pod fine-grained privileges

  (to avoid exposing `cluster-admin` rights to the Pod)

- Level 3: leverage `ownerReferences` to automatically clean up RBAC objects

  (so that nothing is left behind after the Namespace gets deleted)

---

## Script everything

- Feel free to try things manually first

- But make sure to automate the whole process once it works

- E.g. write a script that will create Namespace, Cronjob, etc

  (and that will set the self-destruct timer a couple of minutes in the future)

*See following slides if you need hints!*

---

## Hints for level 1

- Create a Secret holding our kubeconfig file

- Create a Pod mounting the secret

  (e.g. using image `alpine` + `apk add kubectl`)

- Make `kubectl` work in the Pod

  (e.g. with `--kubeconfig` or symlinking `~/.kube/config`)

- Make sure that the Pod destroys the namespace when it starts

  (e.g. by using the correct `command` in the Pod manifest)

- "Upgrade" the Pod to be a CronJob

  (setting the right date+time in the `schedule`)

---

## Hints for level 2

- Create a ServiceAccount for our CronJob

- Create a ClusterRole allowing exclusively to delete the target Namespace

- Create a ClusterRoleBinding linking them together

- Modify the CronJob manifest to use the ServiceAccount

- Test the whole thing!

---

## Hints for level 3

- Make sure that the CronJob and ServiceAccounts are in the Namespace

- Inject the Namespace into the `ownerReferences` of the RBAC objects

- Confirm that the RBAC objects are removed automatically