# Managing secrets

- Sometimes our code needs sensitive information:

  - passwords

  - API tokens

  - TLS keys

  - ...

- *Secrets* can be used for that purpose

- Secrets and ConfigMaps are very similar

---

## Similarities between ConfigMap and Secrets

- ConfigMap and Secrets are key-value maps

  (a Secret can contain zero, one, or many key-value pairs)

- They can both be exposed with the downward API or volumes

- They can both be created with YAML or with a CLI command

  (`kubectl create configmap` / `kubectl create secret`)

---

## ConfigMap and Secrets are different resources

- They can have different RBAC permissions

  (e.g. the default `view` role can read ConfigMaps but not Secrets)

- They indicate a different *intent*:

  *"You should use secrets for things which are actually secret like API keys, 
  credentials, etc., and use config map for not-secret configuration data."*

  *"In the future there will likely be some differentiators for secrets like rotation or support for backing the secret API w/ HSMs, etc."*

  (Source: [the author of both features](https://stackoverflow.com/a/36925553/580281
))

---

## Secrets have an optional *type*

- The type indicates which keys must exist in the secrets, for instance:

  `kubernetes.io/tls` requires `tls.crt` and `tls.key`

  `kubernetes.io/basic-auth` requires `username` and `password`

  `kubernetes.io/ssh-auth` requires `ssh-privatekey`

  `kubernetes.io/dockerconfigjson` requires `.dockerconfigjson`

  `kubernetes.io/service-account-token` requires `token`, `namespace`, `ca.crt`

  (the whole list is in [the documentation](https://kubernetes.io/docs/concepts/configuration/secret/#secret-types))

- This is merely for our (human) convenience:

  “Ah yes, this secret is a ...”


---

## Secrets are displayed with base64 encoding

- When shown with e.g. `kubectl get secrets -o yaml`, secrets are base64-encoded

- Likewise, when defining it with YAML, `data` values are base64-encoded

- Example:
  ```yaml
    kind: Secret
    apiVersion: v1
    metadata:
      name: pin-codes
    data:
      onetwothreefour: MTIzNA==
      zerozerozerozero: MDAwMA==
  ```

- Keep in mind that this is just *encoding*, not *encryption*

- It is very easy to [automatically extract and decode secrets](https://medium.com/@mveritym/decoding-kubernetes-secrets-60deed7a96a3)

---

class: extra-details

## Using `stringData`

- When creating a Secret, it is possible to bypass base64

- Just use `stringData` instead of `data`:
  ```yaml
    kind: Secret
    apiVersion: v1
    metadata:
      name: pin-codes
    stringData:
      onetwothreefour: 1234
      zerozerozerozero: 0000
  ```

- It will show up as base64 if you `kubectl get -o yaml`

- No `type` was specified, so it defaults to `Opaque`

---

class: extra-details

## Encryption at rest

- It is possible to [encrypted secrets at rest](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/)

- This means that secrets will be safe if someone ...

  - steals our etcd servers

  - steals our backups

  - snoops the e.g. iSCSI link between our etcd servers and SAN

- However, starting the API server will now require human intervention

  (to provide the decryption keys)

- This is only for extremely regulated environments (military, nation states...)

---

class: extra-details

## Immutable ConfigMaps and Secrets

- Since Kubernetes 1.19, it is possible to mark a ConfigMap or Secret as *immutable*

  ```bash
  kubectl patch configmap xyz --patch='{"immutable": true}'
  ```

- This brings performance improvements when using lots of ConfigMaps and Secrets

  (lots = tens of thousands)

- Once a ConfigMap or Secret has been marked as immutable:

  - its content cannot be changed anymore
  - the `immutable` field can't be changed back either
  - the only way to change it is to delete and re-create it
  - Pods using it will have to be re-created as well

???

:EN:- Handling passwords and tokens safely

:FR:- Manipulation de mots de passe, clés API etc.
