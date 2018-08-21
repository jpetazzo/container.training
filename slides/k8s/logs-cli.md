# Accessing logs from the CLI

- The `kubectl logs` commands has limitations:

  - it cannot stream logs from multiple pods at a time

  - when showing logs from multiple pods, it mixes them all together

- We are going to see how to do it better

---

## Doing it manually

- We *could* (if we were so inclined), write a program or script that would:

  - take a selector as an argument

  - enumerate all pods matching that selector (with `kubectl get -l ...`)

  - fork one `kubectl logs --follow ...` command per container

  - annotate the logs (the output of each `kubectl logs ...` process) with their origin

  - preserve ordering by using `kubectl logs --timestamps ...` and merge the output

--

- We *could* do it, but thankfully, others did it for us already!

---

## Stern

[Stern](https://github.com/wercker/stern) is an open source project
by [Wercker](http://www.wercker.com/).

From the README:

*Stern allows you to tail multiple pods on Kubernetes and multiple containers within the pod. Each result is color coded for quicker debugging.*

*The query is a regular expression so the pod name can easily be filtered and you don't need to specify the exact id (for instance omitting the deployment id). If a pod is deleted it gets removed from tail and if a new pod is added it automatically gets tailed.*

Exactly what we need!

---

## Installing Stern

- For simplicity, let's just grab a binary release

.exercise[

- Download a binary release from GitHub:
  ```bash
  sudo curl -L -o /usr/local/bin/stern \
       https://github.com/wercker/stern/releases/download/1.6.0/stern_linux_amd64
  sudo chmod +x /usr/local/bin/stern
  ```

]

These installation instructions will work on our clusters, since they are Linux amd64 VMs.

However, you will have to adapt them if you want to install Stern on your local machine.

---

## Using Stern

- There are two ways to specify the pods for which we want to see the logs:

  - `-l` followed by a selector expression (like with many `kubectl` commands)

  - with a "pod query", i.e. a regex used to match pod names

- These two ways can be combined if necessary

.exercise[

- View the logs for all the rng containers:
  ```bash
  stern rng
  ```

]

---

## Stern convenient options

- The `--tail N` flag shows the last `N` lines for each container

  (Instead of showing the logs since the creation of the container)

- The `-t` / `--timestamps` flag shows timestamps

- The `--all-namespaces` flag is self-explanatory

.exercise[

- View what's up with the `weave` system containers:
  ```bash
  stern --tail 1 --timestamps --all-namespaces weave
  ```
]

---

## Using Stern with a selector

- When specifying a selector, we can omit the value for a label

- This will match all objects having that label (regardless of the value)

- Everything created with `kubectl run` has a label `run`

- We can use that property to view the logs of all the pods created with `kubectl run`

.exercise[

- View the logs for all the things started with `kubectl run`:
  ```bash
  stern -l run
  ```

]
