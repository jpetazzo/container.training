# cert-manager

- cert-manager¹ facilitates certificate signing through the Kubernetes API:

  - we create a Certificate object (that's a CRD)

  - cert-manager creates a private key

  - it signs that key ...

  - ... or interacts with a certificate authority to obtain the signature

  - it stores the resulting key+cert in a Secret resource

- These Secret resources can be used in many places (Ingress, mTLS, ...)

.footnote[.red[¹]Always lower case, words separated with a dash; see the [style guide](https://cert-manager.io/docs/faq/style/_.)]

---

## Getting signatures

- cert-manager can use multiple *Issuers* (another CRD), including:

  - self-signed

  - cert-manager acting as a CA

  - the [ACME protocol](https://en.wikipedia.org/wiki/Automated_Certificate_Management_Environment]) (notably used by Let's Encrypt)

  - [HashiCorp Vault](https://www.vaultproject.io/)

- Multiple issuers can be configured simultaneously

- Issuers can be available in a single namespace, or in the whole cluster

  (then we use the *ClusterIssuer* CRD)

---

## cert-manager in action

- We will install cert-manager

- We will create a ClusterIssuer to obtain certificates with Let's Encrypt

  (this will involve setting up an Ingress Controller)

- We will create a Certificate request

- cert-manager will honor that request and create a TLS Secret

---

## Installing cert-manager

- It can be installed with a YAML manifest, or with Helm

.lab[

- Let's install the cert-manager Helm chart with this one-liner:
  ```bash
    helm install cert-manager cert-manager \
        --repo https://charts.jetstack.io \
        --create-namespace --namespace cert-manager \
        --set installCRDs=true
  ```

]

- If you prefer to install with a single YAML file, that's fine too!

  (see [the documentation](https://cert-manager.io/docs/installation/kubernetes/#installing-with-regular-manifests) for instructions)

---

## ClusterIssuer manifest

```yaml
@@INCLUDE[k8s/cm-clusterissuer.yaml]
```

---

## Creating the ClusterIssuer

- The manifest shown on the previous slide is in @@LINK[k8s/cm-clusterissuer.yaml]

.lab[

- Create the ClusterIssuer:
  ```bash
  kubectl apply -f ~/container.training/k8s/cm-clusterissuer.yaml
  ```

]

---

## Certificate manifest

```yaml
@@INCLUDE[k8s/cm-certificate.yaml]
```

- The `name`, `secretName`, and `dnsNames` don't have to match

- There can be multiple `dnsNames`

- The `issuerRef` must match the ClusterIssuer that we created earlier

---

## Creating the Certificate

- The manifest shown on the previous slide is in @@LINK[k8s/cm-certificate.yaml]

.lab[

- Edit the Certificate to update the domain name

  (make sure to replace A.B.C.D with the IP address of one of your nodes!)

- Create the Certificate:
  ```bash
  kubectl apply -f ~/container.training/k8s/cm-certificate.yaml
  ```

]

---

## What's happening?

- cert-manager will create:

  - the secret key

  - a Pod, a Service, and an Ingress to complete the HTTP challenge

- then it waits for the challenge to complete

.lab[

- View the resources created by cert-manager:
  ```bash
    kubectl get pods,services,ingresses \
            --selector=acme.cert-manager.io/http01-solver=true
  ```

]

---

## HTTP challenge

- The CA (in this case, Let's Encrypt) will fetch a particular URL:

  `http://<our-domain>/.well-known/acme-challenge/<token>`

.lab[

- Check the *path* of the Ingress in particular:
  ```bash
    kubectl describe ingress 
            --selector=acme.cert-manager.io/http01-solver=true
  ```

]

---

## What's missing ?

--

An Ingress Controller! 😅

.lab[

- Install an Ingress Controller:
  ```bash
  kubectl apply -f ~/container.training/k8s/traefik-v2.yaml
  ```

- Wait a little bit, and check that we now have a `kubernetes.io/tls` Secret:
  ```bash
  kubectl get secrets
  ```

]

---

class: extra-details

## Using the secret

- For bonus points, try to use the secret in an Ingress!

- This is what the manifest would look like:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: xyz
spec:
  tls:
  - secretName: xyz.A.B.C.D.nip.io
    hosts:
    - xyz.A.B.C.D.nip.io
  rules:
  ...
```

---

class: extra-details

## Automatic TLS Ingress with annotations

- It is also possible to annotate Ingress resources for cert-manager

- If we annotate an Ingress resource with `cert-manager.io/cluster-issuer=xxx`:

  - cert-manager will detect that annotation

  - it will obtain a certificate using the specified ClusterIssuer (`xxx`)

  - it will store the key and certificate in the specified Secret

- Note: the Ingress still needs the `tls` section with `secretName` and `hosts`

---

class: extra-details

## Let's Encrypt and nip.io

- Let's Encrypt has [rate limits](https://letsencrypt.org/docs/rate-limits/) per domain

  (the limits only apply to the production environment, not staging)

- There is a limit of 50 certificates per registered domain

- If we try to use the production environment, we will probably hit the limit

- It's fine to use the staging environment for these experiments

  (our certs won't validate in a browser, but we can always check
  the details of the cert to verify that it was issued by Let's Encrypt!)

???

:EN:- Obtaining certificates with cert-manager
:FR:- Obtenir des certificats avec cert-manager

:T: Obtaining TLS certificates with cert-manager
