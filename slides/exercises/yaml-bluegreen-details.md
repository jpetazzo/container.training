# Exercise — Writing blue/green YAML

- We want to author YAML manifests for the "color" app

  (use image `jpetazzo/color` or `ghcr.io/jpetazzo/color`)

- That app serves web requests on port 80

- We want to deploy two instances of that app (`blue` and `green`)

- We want to expose the app with a service named `front`, such that:

  90% of the requests are sent to `blue`, and 10% to `green`

---

## End goal

- We want to be able to do something like:
  ```bash
  kubectl apply -f blue-green-demo.yaml
  ```

- Then connect to the `front` service and see responses from `blue` and `green`

- Then measure e.g. on 100 requests how many go to `blue` and `green`

  (we want a 90/10 traffic split)

- Go ahead, or check the next slides for hints!

---

## Step 1

- Test the app in isolation:

  - create a Deployment called `blue`

  - expose it with a Service

  - connect to the service and see a "blue" reply

- If you use a `ClusterIP` service:

  - if you're logged directly on the clusters you can connect directly

  - otherwise you can use `kubectl port-forward`

- Otherwise, you can use a `NodePort` or `LoadBalancer` service

---

## Step 2

- Add the `green` Deployment

- Create the `front` service

- Edit the `front` service to replace its selector with a custom one

- Edit `blue` and `green` to add the label(s) of your custom selector

- Check that traffic hits both green and blue

- Think about how to obtain the 90/10 traffic split

---

## Step 3

- Generate, write, extract, ... YAML manifests for all components

  (`blue` and `green` Deployments, `front` Service)

- Check that applying the manifests (e.g. in a brand new namespace) works

- Bonus points: add a one-shot pod to check the traffic split!

---

## Discussion

- Would this be a viable option to obtain, say, a 95% / 5% traffic split?

- What about 99% / 1 %?
