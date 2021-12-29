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

## Accessing private repositories

- Let's see how to access an image on private registry!

- These images are protected by a username + password

  (on some registries, it's token + password, but it's the same thing)

- To access a private image, we need to:

  - create a secret

  - reference that secret in a Pod template

  - or reference that secret in a ServiceAccount used by a Pod

---

## In practice

- Let's try to access an image on a private registry!

  - image = docker-registry.enix.io/jpetazzo/private:latest
  - user = reader
  - password = VmQvqdtXFwXfyy4Jb5DR

.lab[

- Create a Deployment using that image:
  ```bash
    kubectl create deployment priv \
            --image=docker-registry.enix.io/jpetazzo/private
  ```

- Check that the Pod won't start:
  ```bash
  kubectl get pods --selector=app=priv
  ```

]

---

## Creating a secret

- Let's create a secret with the information provided earlier

.lab[

- Create the registry secret:
  ```bash
    kubectl create secret docker-registry enix \
            --docker-server=docker-registry.enix.io \
            --docker-username=reader \
            --docker-password=VmQvqdtXFwXfyy4Jb5DR
  ```

]

Why do we have to specify the registry address?

If we use multiple sets of credentials for different registries, it prevents leaking the credentials of one registry to *another* registry.

---

## Using the secret

- The first way to use a secret is to add it to `imagePullSecrets`

  (in the `spec` section of a Pod template)

.lab[

- Patch the `priv` Deployment that we created earlier:
  ```bash
    kubectl patch deploy priv --patch='
    spec:
      template:
        spec:
          imagePullSecrets:
          - name: enix
    '
  ```

]

---

## Checking the results

.lab[

- Confirm that our Pod can now start correctly:
  ```bash
  kubectl get pods --selector=app=priv
  ```

]

---

## Another way to use the secret

- We can add the secret to the ServiceAccount

- This is convenient to automatically use credentials for *all* pods

  (as long as they're using a specific ServiceAccount, of course)

.lab[

- Add the secret to the ServiceAccount:
  ```bash
    kubectl patch serviceaccount default --patch='
    imagePullSecrets:
    - name: enix
    '
  ```

]

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
