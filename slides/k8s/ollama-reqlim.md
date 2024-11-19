## Setting resource requests and limits

- Thanks to *requests*:

  - our pods will have resources *reserved* for them

  - we won't pack too many pods on a single node

  - cluster autoscaling will trigger when needed (if possible!)

- Thanks to *limits*:

  - our pods won't use more than a given amount of resources

  - they won't use up all the available resources on the node

  - behavior will be more consistent between loaded and unloaded state

---

## Memory

- Personal advice: set request and limit to the same value

- Check current or historical usage and add a bit of padding

  (the more data historical data we have, the less padding we need)

- Consider 10% padding for "dataless" pods, more for pods with data

  (so that the pod has "reserves" for page cache usage)

⚠️ Pods hitting their memory limit will be **killed!**

---

## CPU

- It's not necessary to set requests and limits to the same value

  (this would cause a lot of waste for idle workloads)

- Let's see a few possible strategies!

---

## CPU for mostly idle pods

E.g.: web services, workers handling very few requests...

- Set the limit to at least one whole core
    
  (to avoid throttling, especially on bursty workloads)

- Requests can be very low (e.g. 0.1 core)

⚠️ If requests are too low and the node is very loaded,
the pod will slow down significantly!

(Because CPU cycles are allocated proportionally to CPU requests.)

---

## Inelastic CPU-hungry pods

- Pods with a fixed number of threads:

  *set requests and limits to that number of threads*

- Pods where a specific level of performance needs to be guaranteed:

  *set requests and limits to the number of cores providing that performance*

⚠️ If you set limits to higher levels, performance will be unpredictible!

(You'll get good performance when the node has extra cycles.)

---

## Elastic CPU-hungry pods

- Pods that could potentially use all the cores

  (e.g. machine learning training and inference, depending on the models)

- Decide how many pods per node you want to pack

- Set CPU requests as a fraction of the number of cores of the nodes

  (minus some padding)

- Example:

  - nodes with 32 cores
  - we want 4 pods per node
  - CPU request: 7.5 cores

- Set limits to a higher level (up to node size)

---

## In practice

- Check memory usage of our Ollama pods:
  ```bash
  kubectl top pods
  ```
  (Or even better, look at historical usage in Prometheus or Grafana!)

- Check how many cores we have on our nodes:
  ```bash
  kubectl get nodes -o json | jq .items[].status.capacity.cpu
  kubectl get nodes -o custom-columns=NAME:metadata.name,CPU:status.capacity.cpu
  ```

- Let's decide that we want two Ollama pods per node

- What requests/limits should we set?

---

## Setting resources for Ollama

- Assumptions:

  - we want two pods per node
  - each pod uses ~1500MiB RAM
  - nodes have 4 cores

- We'll set memory requests and limits to 2G

- We'll set CPU requests to 1.5 (4 cores / 2 pods, minus padding)

- We'll set CPU limits to twice the requests

```bash
kubectl set resources deployment ollama \
  --requests=cpu=1.5,memory=2G \
  --limits=cpu=3,memory=2G
```

⚠️ If you have an HAProxy side car, this will set its resources too!

---

## Results

- After setting these resource requests, we should see cluster autoscaling

- If not: scale up the Ollama Deployment to at least 3 replicas

- Check cluster autoscaler status with:
  ```bash
  kubectl describe configmap --namespace kube-system cluster-autoscaler-status
  ```
