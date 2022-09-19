# Running our first containers on Kubernetes

- First things first: we cannot run a container

--

- We are going to run a pod, and in that pod there will be a single container

--

- In that container in the pod, we are going to run a simple `ping` command

---

## Starting a simple pod with `kubectl run`

- `kubectl run` is convenient to start a single pod

- We need to specify at least a *name* and the image we want to use

- Optionally, we can specify the command to run in the pod

.lab[

- Let's ping the address of `localhost`, the loopback interface:
  ```bash
  kubectl run pingpong --image alpine ping 127.0.0.1
  ```

<!-- ```hide kubectl wait pod --selector=run=pingpong --for condition=ready``` -->

]

The output tells us that a Pod was created:
```
pod/pingpong created
```

---

## Viewing container output

- Let's use the `kubectl logs` command

- It takes a Pod name as argument

- Unless specified otherwise, it will only show logs of the first container in the pod

  (Good thing there's only one in ours!)

.lab[

- View the result of our `ping` command:
  ```bash
  kubectl logs pingpong
  ```

]

---

## Streaming logs in real time

- Just like `docker logs`, `kubectl logs` supports convenient options:

  - `-f`/`--follow` to stream logs in real time (à la `tail -f`)

  - `--tail` to indicate how many lines you want to see (from the end)

  - `--since` to get logs only after a given timestamp

.lab[

- View the latest logs of our `ping` command:
  ```bash
  kubectl logs pingpong --tail 1 --follow
  ```

- Stop it with Ctrl-C

<!--
```wait seq=3```
```keys ^C```
-->

]

---

## Authoring YAML

- We have already generated YAML implicitly, with e.g.:

  - `kubectl run`

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
  kubectl run pingpong --image alpine --dry-run=client ping 127.0.0.1

  kubectl run pingpong --image alpine --dry-run=client ping 127.0.0.1 >ping.yaml
  ```

- Optionally clean it up with `kubectl neat`, too

  ```bash
  kubectl apply -f ping.yaml
  ```

]


---

class: extra-details

## Server-side dry run

- Server-side dry run will do all the work, but *not* persist to etcd

  (all validation and mutation hooks will be executed)

.lab[

- Try the same YAML file as earlier, with server-side dry run:
  ```bash
  kubectl run pingpong --image alpine --dry-run=server ping 127.0.0.1
  ```

]


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

- Get started with `kubectl run ...` 

  (until you have something that sort of works)

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



---


## Multi-Line Command arguments


.lab[
  ```bash
/bin/sh -c    takes a single string parameter

    - command:
      - /bin/sh
      - -c
      - |
        echo "running below scripts"
        i=0;
        while true;
        do
          echo "$i: $(date)";
          i=$((i+1));
          sleep 1;
        done
  ```
]