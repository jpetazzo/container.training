# Exercise — Writing YAML

- We want to generate YAML manifests for the dockercoins app

- Reminder: it includes 5 Deployments and 4 Services

- Feel free to put everything in a single file, or one file per manifest

- The manifests can be:

  - authored (based on examples found in the Kubernetes docs or online)

  - generated (with `kubectl create ... --dry-run -o yaml` or some web app)

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
