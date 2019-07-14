# Authentication and authorization

*And first, a little refresher!*

- Authentication = verifying the identity of a person

  On a UNIX system, we can authenticate with login+password, SSH keys ...

- Authorization = listing what they are allowed to do

  On a UNIX system, this can include file permissions, sudoer entries ...

- Sometimes abbreviated as "authn" and "authz"

- In good modular systems, these things are decoupled

   (so we can e.g. change a password or SSH key without having to reset access rights)

---

## Authentication in Kubernetes

- When the API server receives a request, it tries to authenticate it

  (it examines headers, certificates... anything available)

- Many authentication methods are available and can be used simultaneously

  (we will see them on the next slide)

- It's the job of the authentication method to produce:

  - the user name
  - the user ID
  - a list of groups

- The API server doesn't interpret these; that'll be the job of *authorizers*

---

## Authentication methods

- TLS client certificates

  (that's what we've been doing with `kubectl` so far)

- Bearer tokens

  (a secret token in the HTTP headers of the request)

- [HTTP basic auth](https://en.wikipedia.org/wiki/Basic_access_authentication)

  (carrying user and password in an HTTP header)

- Authentication proxy

  (sitting in front of the API and setting trusted headers)

---

## Anonymous & unauthenticated requests

- If any authentication method *rejects* a request, it's denied

  (`401 Unauthorized` HTTP code)

- If a request is neither rejected nor accepted by anyone, it's anonymous

  - the user name is `system:anonymous`

  - the list of groups is `[system:unauthenticated]`

- By default, the anonymous user can't do anything


.exercise[

- Note that 401 (not 403) is what you get if you just `curl` the Kubernetes API
  ```bash
    curl -k $API_URL
  ```

]

---

## Authentication with tokens

- Tokens are passed as HTTP headers:

  `Authorization: Bearer and-then-here-comes-the-token`

- Tokens can be validated through a number of different methods:

  - static tokens hard-coded in a file on the API server

  - [bootstrap tokens](https://kubernetes.io/docs/reference/access-authn-authz/bootstrap-tokens/) (special case to create a cluster or join nodes)

  - [OpenID Connect tokens](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#openid-connect-tokens) (to delegate authentication to compatible OAuth2 providers)

  - service accounts (these deserve more details, coming right up!)

---

## Service accounts

- A service account is a user that exists in the Kubernetes API

  (it is visible with e.g. `kubectl get serviceaccounts`)

- Service accounts can therefore be created / updated dynamically

  (they don't require hand-editing a file and restarting the API server)

- A service account is associated with a set of secrets

  (the kind that you can view with `kubectl get secrets`)

- Service accounts are generally used to grant permissions to applications, services...

  (as opposed to humans)

---

class: extra-details

## Token authentication in practice

- We are going to list existing service accounts

- Then we will extract the token for a given service account

- And we will use that token to authenticate with the API

---

class: extra-details

## Listing service accounts

.exercise[

- The resource name is `serviceaccount` or `sa` for short:
  ```bash
  kubectl get sa
  ```

]

There should be just one service account in the default namespace: `default`.

---

class: extra-details

## Finding the secret

.exercise[

- List the secrets for the `default` service account:
  ```bash
  kubectl get sa default -o yaml
  SECRET=$(kubectl get sa default -o json | jq -r .secrets[0].name)
  echo $SECRET
  ```

]

It should be named `default-token-XXXXX`.

---

class: extra-details

## Extracting the token

- The token is stored in the secret, wrapped with base64 encoding

.exercise[

- View the secret:
  ```bash
  kubectl get secret $SECRET -o yaml
  ```

- Extract the token and decode it:
  ```bash
  TOKEN=$(kubectl get secret $SECRET -o json \
          | jq -r .data.token | openssl base64 -d -A)
  ```

]

---

class: extra-details

## Using the token

- Let's send a request to the API, without and with the token

.exercise[

- Find the URL for the `kubernetes` master:
  ```bash
  kubectl cluster-info
  ```
- Set it programmatically, if AKS_NAME is set: (choose from `kubectl config view`):
  ```bash
  API=$(kubectl config view -o \
        jsonpath="{.clusters[?(@.name==\"$AKS_NAME\")].cluster.server}")
  ```
- Connect without the token, then with the token::
  ```bash
  curl -k $API
  curl -k -H "Authorization: Bearer $TOKEN" $API
  ```

]

---

## Authorization in Kubernetes

- There are multiple ways to grant permissions in Kubernetes, called [authorizers](https://kubernetes.io/docs/reference/access-authn-authz/authorization/#authorization-modules):

  - [Node Authorization](https://kubernetes.io/docs/reference/access-authn-authz/node/) (used internally by kubelet; we can ignore it)

  - [Attribute-based access control](https://kubernetes.io/docs/reference/access-authn-authz/abac/) (powerful but complex and static; ignore it too)

  - [Webhook](https://kubernetes.io/docs/reference/access-authn-authz/webhook/) (each API request is submitted to an external service for approval)

  - [Role-based access control](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) (associates permissions to users dynamically)

- The one we want is the last one, generally abbreviated as RBAC

---

## Role-based access control

- RBAC allows to specify fine-grained permissions

- Permissions are expressed as *rules*

- A rule is a combination of:

  - [verbs](https://kubernetes.io/docs/reference/access-authn-authz/authorization/#determine-the-request-verb) like create, get, list, update, delete...

  - resources (as in "API resource," like pods, nodes, services...)

  - resource names (to specify e.g. one specific pod instead of all pods)

  - in some case, [subresources](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#referring-to-resources) (e.g. logs are subresources of pods)

---

## From rules to roles to rolebindings

- A *role* is an API object containing a list of *rules*

  Example: role "external-load-balancer-configurator" can:
  - [list, get] resources [endpoints, services, pods]
  - [update] resources [services]

- A *rolebinding* associates a role with a user

  Example: rolebinding "external-load-balancer-configurator":
  - associates user "external-load-balancer-configurator"
  - with role "external-load-balancer-configurator"

- Yes, there can be users, roles, and rolebindings with the same name

- It's a good idea for 1-1-1 bindings; not so much for 1-N ones

---

## Cluster-scope permissions

- API resources Role and RoleBinding are for objects within a namespace

- We can also define API resources ClusterRole and ClusterRoleBinding

- These are a superset, allowing us to:

  - specify actions on cluster-wide objects (like nodes)

  - operate across all namespaces

- We can create Role and RoleBinding resources within a namespace

- ClusterRole and ClusterRoleBinding resources are global

---

## Pods and service accounts

- A pod can be associated with a service account

  - by default, it is associated with the `default` service account

  - as we saw earlier, this service account has no permissions anyway

- The associated token is exposed to the pod's filesystem

  (in `/var/run/secrets/kubernetes.io/serviceaccount/token`)

- Standard Kubernetes tooling (like `kubectl`) will look for it there

- So Kubernetes tools running in a pod will automatically use the service account

---

class: extra-details

## Pod Security Policies

- If you'd like to check out pod-level controls in AKS, they are [available in preview](https://docs.microsoft.com/en-us/azure/aks/use-pod-security-policies)

- Experiment, but not in production!
