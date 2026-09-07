# Exercise — Writing YAML

- We want to generate YAML manifests for the dockercoins app

- Reminder: it includes 5 Deployments and 4 Services

- Feel free to put everything in a single file, or one file per manifest

- The manifests can be:

  - authored (based on examples found in the Kubernetes docs or online)

  - generated (with `kubectl create ... --dry-run -o yaml`, some web app, or an LLM)

  - dumped (with `kubectl get ... -o yaml`) from existing resources

- Use whatever works best for you!

---

## Goal

- It should be possible to deploy dockercoins by doing:
  ```bash
  kubectl create namespace dockercoins
  kubectl apply --namespace dockercoins -f `...`
  ```

- Reminder: the argument given to `-f` can be a directory

  (in which case all the YAML files in the directory will be processed)

- Bonus: try to minimize the manifests by removing empty or optional fields

- Compare your manifests with [the ones in the container.training repository][manifests]

[manifests]: https://github.com/jpetazzo/container.training/blob/main/k8s/dockercoins.yaml

---

## And now?

- We want to change the architecture of the app:

  *run it as a single Pod (with 5 containers) instead of 5 Deployments*

- Requirement: keep the same images (do not change the code!)

- There should still be a `webui` service exposing the web UI

- See next slide if you need hints!

---

## Hints

- Create a manifest (Pod, ReplicaSet, Deployment... it doesn't matter)

- Add 5 containers using our 5 images

- Start the Pod and check the logs... What's happening?

--

- We have *port conflicts!*

- We need to make sure that each web service listens on a different port

- Hint: check the Dockerfiles for `hasher` and `rng`

--

- For `hasher`, change the port with a `command:` block

- For `rng`, change the port with an `env:` block

---

## More hints

- *Normally,* at this point, all 5 containers are running

- But the worker is still having problems... Why?

--

- We need to update our Services

- Check the `targetPort` option!

- After updating the Services, worker and webUI should work correctly

---

## And now?

- The worker connects to `redis`, `rng`, and `hasher` through a Service

- Can we get rid of that service?

- Check next slide for hints...

--

- Since all containers run in the same pod, they can communicate over loopback

- Instead of changing the port for `rng` and `hasher`, change the *address*

  (for instance, binding to 127.0.0.2 and 127.0.0.3)

- Then we need to make sure that `rng` and `hasher` resolve to these addresses

- One possibility: combine `nip.io` and a Service of type `ExternalName`

- Good luck!
