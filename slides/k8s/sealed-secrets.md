# Sealed Secrets

- Kubernetes provides the "Secret" resource to store credentials, keys, passwords ...

- Secrets can be protected with RBAC

  (e.g. "you can write secrets, but only the app's service account can read them")

- [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) is an operator that lets us store secrets in code repositories

- It uses asymetric cryptography:

  - anyone can *encrypt* a secret

  - only the cluster can *decrypt* a secret

---

## Principle

- The Sealed Secrets operator uses a *public* and a *private* key

- The public key is available publicly (duh!)

- We use the public key to encrypt secrets into a SealedSecret resource

- the SealedSecret resource can be stored in a code repo (even a public one)

- The SealedSecret resource is `kubectl apply`'d to the cluster

- The Sealed Secrets controller decrypts the SealedSecret with the private key

  (this creates a classic Secret resource)

- Nobody else can decrypt secrets, since only the controller has the private key

---

## In action

- We will install the Sealed Secrets operator

- We will generate a Secret

- We will "seal" that Secret (generate a SealedSecret)

- We will load that SealedSecret on the cluster

- We will check that we now have a Secret

---

## Installing the operator

- The official installation is done through a single YAML file

- There is also a Helm chart if you prefer that (see next slide!)

<!-- #VERSION# -->

.lab[

- Install the operator:
  .small[
  ```bash
    kubectl apply -f \
            https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.17.4/controller.yaml
  ```
  ]

]

Note: it installs into `kube-system` by default.

If you change that, you will also need to inform `kubeseal` later on.

---

class: extra-details

## Installing with Helm

- The Sealed Secrets controller can be installed like this:

  ```bash
    helm install --repo https://bitnami-labs.github.io/sealed-secrets/ \
         sealed-secrets-controller sealed-secrets --namespace kube-system
  ```

- Make sure to install in the `kube-system` Namespace

- Make sure that the release is named `sealed-secrets-controller`

  (or pass a `--controller-name` option to `kubeseal` later)

---

## Creating a Secret

- Let's create a normal (unencrypted) secret

.lab[

- Create a Secret with a couple of API tokens:
  ```bash
    kubectl create secret generic awskey \
            --from-literal=AWS_ACCESS_KEY_ID=AKI... \
            --from-literal=AWS_SECRET_ACCESS_KEY=abc123xyz... \
            --dry-run=client -o yaml > secret-aws.yaml
  ```

]

- Note the `--dry-run` and `-o yaml`

  (we're just generating YAML, not sending the secrets to our Kubernetes cluster)

- We could also write the YAML from scratch or generate it with other tools

---

## Creating a Sealed Secret

- This is done with the `kubeseal` tool

- It will obtain the public key from the cluster

.lab[

- Create the Sealed Secret:
  ```bash
    kubeseal < secret-aws.yaml > sealed-secret-aws.json
  ```

]

- The file `sealed-secret-aws.json` can be committed to your public repo

  (if you prefer YAML output, you can add `-o yaml`)

---

## Using a Sealed Secret

- Now let's `kubectl apply` that Sealed Secret to the cluster

- The Sealed Secret controller will "unseal" it for us

.lab[

- Check that our Secret doesn't exist (yet):
  ```bash
  kubectl get secrets
  ```

- Load the Sealed Secret into the cluster:
  ```bash
  kubectl create -f sealed-secret-aws.json
  ```

- Check that the secret is now available:
  ```bash
  kubectl get secrets
  ```

]

---

## Tweaking secrets

- Let's see what happens if we try to rename the Secret

  (or use it in a different namespace)

.lab[

- Delete both the Secret and the SealedSecret

- Edit `sealed-secret-aws.json`

- Change the name of the secret, or its namespace

  (both in the SealedSecret metadata and in the Secret template)

- `kubectl apply -f` the new JSON file and observe the results 🤔

]

---

## Sealed Secrets are *scoped*

- A SealedSecret cannot be renamed or moved to another namespace

  (at least, not by default!)

- Otherwise, it would allow to evade RBAC rules:

  - if I can view Secrets in namespace `myapp` but not in namespace `yourapp`

  - I could take a SealedSecret belonging to namespace `yourapp`

  - ... and deploy it in `myapp`

  - ... and view the resulting decrypted Secret!

- This can be changed with `--scope namespace-wide` or `--scope cluster-wide`

---

## Working offline

- We can obtain the public key from the server

  (technically, as a PEM certificate)

- Then we can use that public key offline

  (without contacting the server)

- Relevant commands:

  `kubeseal --fetch-cert > seal.pem`

  `kubeseal --cert seal.pem < secret.yaml > sealedsecret.json`

---

## Key rotation

- The controller generate new keys every month by default

- The keys are kept as TLS Secrets in the `kube-system` namespace

  (named `sealed-secrets-keyXXXXX`)

- When keys are "rotated", old decryption keys are kept

  (otherwise we can't decrypt previously-generated SealedSecrets)

---

## Key compromise

- If the *sealing* key (obtained with `--fetch-cert` is compromised):

  *we don't need to do anything (it's a public key!)*

- However, if the *unsealing* key (the TLS secret in `kube-system`) is compromised ...

  *we need to:*

  - rotate the key

  - rotate the SealedSecrets that were encrypted with that key
    <br/>
    (as they are compromised)

---

## Rotating the key

- By default, new keys are generated every 30 days

- To force the generation of a new key "right now":

  - obtain an RFC1123 timestamp with `date -R`

  - edit Deployment `sealed-secrets-controller` (in `kube-system`)

  - add `--key-cutoff-time=TIMESTAMP` to the command-line

- *Then*, rotate the SealedSecrets that were encrypted with it

  (generate new Secrets, then encrypt them with the new key)

---

## Discussion (the good)

- The footprint of the operator is rather small:

  - only one CRD

  - one Deployment, one Service

  - a few RBAC-related objects

---

## Discussion (the less good)

- Events could be improved

  - `no key to decrypt secret` when there is a name/namespace mismatch

  - no event indicating that a SealedSecret was successfully unsealed

- Key rotation could be improved (how to find secrets corresponding to a key?)

- If the sealing keys are lost, it's impossible to unseal the SealedSecrets

  (e.g. cluster reinstall)

- ... Which means that we need to back up the sealing keys

- ... Which means that we need to be super careful with these backups!

---

## Other approaches

- [Kamus](https://kamus.soluto.io/) ([git](https://github.com/Soluto/kamus)) offers "zero-trust" secrets

  (the cluster cannot decrypt secrets; only the application can decrypt them)

- [Vault](https://learn.hashicorp.com/tutorials/vault/kubernetes-sidecar?in=vault/kubernetes) can do ... a lot

  - dynamic secrets (generated on the fly for a consumer)

  - certificate management

  - integration outside of Kubernetes

  - and much more!

???

:EN:- The Sealed Secrets Operator
:FR:- L'opérateur *Sealed Secrets*