# ExternalDNS

- https://github.com/kubernetes-sigs/external-dns

- Open source controller

- “Configure external DNS servers dynamically from Kubernetes resources”

- ExternalDNS will automatically create DNS records from Kubernetes resources

- Example:

  - we own the domain `example.com`

  - we create an Ingress resource for `dev.example.com`

  - ExternalDNS automatically creates a DNS record for `dev.example.com`
    <br/>(with the IP address used by our Ingress Controller)

---

## Supported Kubernetes resources

- Services

- Ingresses

- HTTPRoutes (Gateway API)

- Nodes

- [And much more!][externaldns-sources]

(ExternalDNS call these "sources".)

[externaldns-sources]: https://kubernetes-sigs.github.io/external-dns/latest/docs/sources/about/

---

## Supported DNS providers

- [More than 25 providers are supported "in-tree"][externaldns-intree]

- [At least as many are supported out of tree, through a webhook system][externaldns-webhooks]

- These providers include:

  - cloud providers like Route53, CloudFlare, Exoscale, Linode, OVHcloud, Scaleway...

  - self-hosted DNS like PowerDNS, CoreDNS...

  - DNS included in routers and similar appliances like Microtik, Pi-Hole...

  - generic DNS update protocols like the one defined in [RFC2136]

[externaldns-intree]: https://kubernetes-sigs.github.io/external-dns/latest/docs/providers/
[externaldns-webhooks]: https://kubernetes-sigs.github.io/external-dns/latest/#new-providers
[RFC2136]: https://datatracker.ietf.org/doc/html/rfc2136

---

## Order of operations

1. Have a domain name

2. Set up the domain name with a DNS provider

3. Install and configure ExternalDNS

4. Create Kubernetes resources; for instance:

   - a Service with the annotation `external-dns.alpha.kubernetes.io/hostname`

   - an Ingress mentioning one or multiple hosts

---

## What are we going to use?

- If you need a domain name, you can get a cheap one from one of these providers:

  [Porkbun] / [Infomaniak] / [BookMyName]

  (we're not affiliated with them, but we're happy customers!)

- For the DNS provider, we're going to use Linode DNS

  (but anything else will work just as well)

[Porkbun]: https://porkbun.com
[Infomaniak]: https://infomaniak.com/en/domains
[BookMyName]: https://bookmyname.com

---

## Prep work

- Make sure that the domain name is set up to use the DNS provider

  (technically the "NS records" should be set up properly)

- Make sure that you have an API token for the DNS provider

  (or whatever equivalent is necessary to update DNS records there)

- Pro-tip: change the default TTL for the domain to a relatively low value

  (e.g. 300 seconds / 5 minutes)

- This will be useful to reduce the impact of *negative caching* when testing

  (i.e. accessing an entry that doesn't exist yet)

---

## Deploying ExternalDNS

- Option 1: use the container image
  <br/>(`registry.k8s.io/external-dns/external-dns`)

  - create a Deployment using the image
  - ideally, set up RBAC resources (ServiceAccount, ClusterRole, ClusterRoleBinding)
  - configure through command-line flags or environment variables

- Option 2: use the upstream Helm chart
  <br/>(https://artifacthub.io/packages/helm/external-dns/external-dns)

  - set value `provider.name`
  - set value `env` to pass configuration options (e.g. provider credentials)

- Option 3: use the Bitnami Helm chart

  ⚠️ NOT RECOMMENDED DUE TO BROADCOM'S LICENSING CHANGES

---

## Using the official Helm chart

- We're going to install ExternalDNS with the official Helm chart

- We'll put the Linode API token in a separate Secret

- We'll reference that Secret in the chart configuration values

- This means that we could manage that secret with a separate process

  (e.g. [External Secrets Operator][eso], [Sealed Secrets][sealed-secrets]...)

[eso]: https://external-secrets.io/latest/
[sealed-secrets]: https://github.com/bitnami-labs/sealed-secrets

---

## Installing the chart

- We're doing this first, because it will create the `external-dns` Namespace

.lab[

- Create the `external-dns` Namespace and deploy ExternalDNS there:
  ```bash
    helm upgrade --install external-dns external-dns \
      --repo https://kubernetes-sigs.github.io/external-dns/ \
      --namespace external-dns --create-namespace \
      --set provider.name=linode \
      --set env[0].name=LINODE_TOKEN \
      --set env[0].valueFrom.secretKeyRef.name=external-dns \
      --set env[0].valueFrom.secretKeyRef.key=LINODE_TOKEN \
      #
  ```

]

---

## Creating the Secret

- First, create an API token on Linode

  (it should be on [that page](https://cloud.linode.com/profile/tokens), then click `Create A Personal Access Token`)

.lab[

- Create a Secret with our new API token:
  ```bash
    kubectl create secret generic external-dns --namespace external-dns \
      --from-literal=LINODE_TOKEN=`...`
  ```

]

---

## Checking that ExternalDNS is up and running

- Note that it might take a minute for ExternalDNS to start successfully

  (because the Secret didn't exist yet when we deployed the chart)

.lab[

- Check the status of the pods:
  ```bash
  kubectl get pods --namespace=external-dns
  ```

]

- If the Pod is in status `CreateContainerConfigError`, give it a minute

  (and/or check what's going on with `kubectl describe`)

---

## Testing ExternalDNS

- Assuming that our domain is `example.com`...

- We can annotate a `LoadBalancer` Service to add a record for its `ExternalIP`:
  ```bash
    kubectl annotate service web \
      external-dns.alpha.kubernetes.io/hostname=demo-public.`example.com`
  ```

- We can also annotate a `ClusterIP` Service to add a record for its `ClusterIP`:
  ```bash
    kubectl annotate service web \
      external-dns.alpha.kubernetes.io/internal-hostname=demo-private.`example.com`
  ```

---

## Troubleshooting

- Check ExternalDNS logs:
  ```bash
    kubectl logs -n external-dns -l app.kubernetes.io/name=external-dns
  ```

- The DNS records should also show up in Linode DNS web interface

---

class: extra-details

## Ingress

- When using ExternalDNS with Ingress resources:

  *make sure that the ADDRESS field in the Ingress isn't blank!*

- ExternalDNS uses that field to know the IP address to use in DNS records

- This field should be automatically filled by the Ingress Controller

- Some Ingress Controllers don't to it automatically

  (and might require additional configuration)

- Example: for Traefik, look for option `publishedService`

???

:EN:- Deploying ExternalDNS
:FR:- Déployer ExternalDNS
