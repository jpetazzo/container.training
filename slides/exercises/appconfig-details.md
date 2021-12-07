# Exercise — Application Configuration

- We want to configure an application with a ConfigMap

- We will use the "rainbow" example shown previously

  (HAProxy load balancing traffic to services in multiple namespaces)

- We won't provide the HAProxy configuration file

- Instead, we will provide a list of namespaces

  (e.g. as a space-delimited list in a ConfigMap)

- Our Pod should generate the HAProxy configuration using the ConfigMap

---

## Setup

- Let's say that we have the "rainbow" app deployed:
  ```bash
  kubectl apply -f ~/container.training/k8s/rainbow.yaml
  ```

- And a ConfigMap like the following one:
  ```bash
  kubectl create configmap rainbow --from-literal=namespaces="blue green"
  ```

---

## Goal 1

- We want a Deployment and a Service called `rainbow`

- The `rainbow` Service should load balance across Namespaces `blue` and `green`

  (i.e. to the Services called `color` in both these Namespaces)

- We want to be able to update the configuration:

  - update the ConfigMap to put `blue green red`

  - what should we do so that HAproxy picks up the change?

---

## Goal 2

- Check what happens if we specify a backend that doesn't exist

  (e.g. add `purple` to the list of namespaces)

- If we specify invalid backends to HAProxy, it won't start!

- Implement a workaround among these two:

  - remove invalid backends from the list before starting HAProxy

  - wait until all backends are valid before starting HAProxy

---

## Goal 3

- We'd like HAProxy to pick up ConfigMap updates automatically

- How can we do that?

---

## Hints

- Check the following slides if you need help!

--

- We want to generate the HAProxy configuration in an `initContainer`

--

- The `namespaces` entry of the `rainbow` ConfigMap should be exposed to the `initContainer`

--

- The HAProxy configuration should be in a volume shared with HAProxy
