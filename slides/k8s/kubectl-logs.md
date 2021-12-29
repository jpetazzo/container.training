# Revisiting `kubectl logs`

- In this section, we assume that we have a Deployment with multiple Pods

  (e.g. `pingpong` that we scaled to at least 3 pods)

- We will highlights some of the limitations of `kubectl logs`

---

## Streaming logs of multiple pods

- By default, `kubectl logs` shows us the output of a single Pod

.lab[

- Try to check the output of the Pods related to a Deployment:
  ```bash
  kubectl logs deploy/pingpong --tail 1 --follow
  ```

<!--
```wait using pod/pingpong-```
```keys ^C```
-->

]

`kubectl logs` only shows us the logs of one of the Pods.

---

## Viewing logs of multiple pods

- When we specify a deployment name, only one single pod's logs are shown

- We can view the logs of multiple pods by specifying a *selector*

- If we check the pods created by the deployment, they all have the label `app=pingpong`

  (this is just a default label that gets added when using `kubectl create deployment`)

.lab[

- View the last line of log from all pods with the `app=pingpong` label:
  ```bash
  kubectl logs -l app=pingpong --tail 1
  ```

]

---

## Streaming logs of multiple pods

- Can we stream the logs of all our `pingpong` pods?

.lab[

- Combine `-l` and `-f` flags:
  ```bash
  kubectl logs -l app=pingpong --tail 1 -f
  ```

<!--
```wait seq=```
```key ^C```
-->

]

*Note: combining `-l` and `-f` is only possible since Kubernetes 1.14!*

*Let's try to understand why ...*

---

class: extra-details

## Streaming logs of many pods

- Let's see what happens if we try to stream the logs for more than 5 pods

.lab[

- Scale up our deployment:
  ```bash
  kubectl scale deployment pingpong --replicas=8
  ```

- Stream the logs:
  ```bash
  kubectl logs -l app=pingpong --tail 1 -f
  ```

<!-- ```wait error:``` -->

]

We see a message like the following one:
```
error: you are attempting to follow 8 log streams,
but maximum allowed concurency is 5,
use --max-log-requests to increase the limit
```

---

class: extra-details

## Why can't we stream the logs of many pods?

- `kubectl` opens one connection to the API server per pod

- For each pod, the API server opens one extra connection to the corresponding kubelet

- If there are 1000 pods in our deployment, that's 1000 inbound + 1000 outbound connections on the API server

- This could easily put a lot of stress on the API server

- Prior Kubernetes 1.14, it was decided to *not* allow multiple connections

- From Kubernetes 1.14, it is allowed, but limited to 5 connections

  (this can be changed with `--max-log-requests`)

- For more details about the rationale, see
  [PR #67573](https://github.com/kubernetes/kubernetes/pull/67573)

---

## Shortcomings of `kubectl logs`

- We don't see which pod sent which log line

- If pods are restarted / replaced, the log stream stops

- If new pods are added, we don't see their logs

- To stream the logs of multiple pods, we need to write a selector

- There are external tools to address these shortcomings

  (e.g.: [Stern](https://github.com/wercker/stern))

---

class: extra-details

## `kubectl logs -l ... --tail N`

- If we run this with Kubernetes 1.12, the last command shows multiple lines

- This is a regression when `--tail` is used together with `-l`/`--selector`

- It always shows the last 10 lines of output for each container

  (instead of the number of lines specified on the command line)

- The problem was fixed in Kubernetes 1.13

*See [#70554](https://github.com/kubernetes/kubernetes/issues/70554) for details.*

???

:EN:- Viewing logs with "kubectl logs"
:FR:- Consulter les logs avec "kubectl logs"
