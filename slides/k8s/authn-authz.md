# Authentication and authorization

- In this section, we will:

  - define authentication and authorization

  - explain how they are implemented in Kubernetes

  - talk about tokens, certificates, service accounts, RBAC ...

- But first: why do we need all this?

---

## The need for fine-grained security

- The Kubernetes API should only be available for identified users

  - we don't want "guest access" (except in very rare scenarios)

  - we don't want strangers to use our compute resources, delete our apps ...

  - our keys and passwords should not be exposed to the public

- Users will often have different access rights

  - cluster admin (similar to UNIX "root") can do everything

  - developer might access specific resources, or a specific namespace

  - supervision might have read only access to *most* resources

---

## Example: custom HTTP load balancer

- Let's imagine that we have a custom HTTP load balancer for multiple apps

- Each app has its own *Deployment* resource

- By default, the apps are "sleeping" and scaled to zero

- When a request comes in, the corresponding app gets woken up

- After some inactivity, the app is scaled down again

- This HTTP load balancer needs API access (to scale up/down)

- What if *a wild vulnerability appears*?

---

## Consequences of vulnerability

- If the HTTP load balancer has the same API access as we do:

  *full cluster compromise (easy data leak, cryptojacking...)*

- If the HTTP load balancer has `update` permissions on the Deployments:

  *defacement (easy), MITM / impersonation (medium to hard)*

- If the HTTP load balancer only has permission to `scale` the Deployments:

  *denial-of-service*

- All these outcomes are bad, but some are worse than others

---

## Definitions

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

  (that's the default for clusters provisioned with `kubeadm`)

- Bearer tokens

  (a secret token in the HTTP headers of the request)

- [HTTP basic auth](https://en.wikipedia.org/wiki/Basic_access_authentication)

  (carrying user and password in an HTTP header; [deprecated since Kubernetes 1.19](https://github.com/kubernetes/kubernetes/pull/89069))

- Authentication proxy

  (sitting in front of the API and setting trusted headers)

---

## Anonymous requests

- If any authentication method *rejects* a request, it's denied

  (`401 Unauthorized` HTTP code)

- If a request is neither rejected nor accepted by anyone, it's anonymous

  - the user name is `system:anonymous`

  - the list of groups is `[system:unauthenticated]`

- By default, the anonymous user can't do anything

  (that's what you get if you just `curl` the Kubernetes API)

---

## Authentication with TLS certificates

- Enabled in almost all Kubernetes deployments

- The user name is indicated by the `CN` in the client certificate

- The groups are indicated by the `O` fields in the client certificate

- From the point of view of the Kubernetes API, users do not exist

  (i.e. there is no resource with `kind: User`)

- The Kubernetes API can be set up to use your custom CA to validate client certs

---

class: extra-details

## Authentication for kubelet

- In most clusters, kubelets authenticate using certificates

  (`O=system:nodes`, `CN=system:node:name-of-the-node`)

- The Kubernetse API can act as a CA

  (by wrapping an X509 CSR into a CertificateSigningRequest resource)

- This enables kubelets to renew their own certificates

- It can also be used to issue user certificates

  (but it lacks flexibility; e.g. validity can't be customized)

---

## User certificates in practice

- The Kubernetes API server does not support certificate revocation

  (see issue [#18982](https://github.com/kubernetes/kubernetes/issues/18982))

- As a result, we don't have an easy way to terminate someone's access

  (if their key is compromised, or they leave the organization)

- Issue short-lived certificates if you use them to authenticate users!

  (short-lived = a few hours)

- This can be facilitated by e.g. Vault, cert-manager...

---

## What if a certificate is compromised?

- Option 1: wait for the certificate to expire

  (which is why short-lived certs are convenient!)

- Option 2: remove access from that certificate's user and groups

  - if that user was `bob.smith`, create a new user `bob.smith.2`

  - if Bob was in groups `dev`, create a new group `dev.2`

  - let's agree that this is not a great solution!

- Option 3: re-create a new CA and re-issue all certificates

  - let's agree that this is an even worse solution!

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

## Checking our authentication method

- Let's check our kubeconfig file

- Do we have a certificate, a token, or something else?

---

class: extra-details

## Inspecting a certificate

If we have a certificate, let's use the following command:

```bash
kubectl config view \
        --raw \
        -o json \
        | jq -r .users[0].user[\"client-certificate-data\"] \
        | openssl base64 -d -A \
        | openssl x509 -text \
        | grep Subject:
```

This command will show the `CN` and `O` fields for our certificate.

---

class: extra-details

## Breaking down the command

- `kubectl config view` shows the Kubernetes user configuration
- `--raw` includes certificate information (which shows as REDACTED otherwise)
- `-o json` outputs the information in JSON format
- `| jq ...` extracts the field with the user certificate (in base64)
- `| openssl base64 -d -A` decodes the base64 format (now we have a PEM file)
- `| openssl x509 -text` parses the certificate and outputs it as plain text
- `| grep Subject:` shows us the line that interests us

→ We are user `kubernetes-admin`, in group `system:masters`.

(We will see later how and why this gives us the permissions that we have.)

---

class: extra-details

## Inspecting a token

If we have a token, let's use the following command:

```bash
kubectl config view \
        --raw \
        -o json \
        | jq -r .users[0].user.token \
        | base64 -d \
        | cut -d. -f2 \
        | base64 -d \
        | jq .
```

If our token is a JWT / OIDC token, this command will show its content.

---

class: extra-details

## Other authentication methods

- Other types of tokens

  - these tokens are typically shorter than JWT or OIDC tokens

  - it is generally not possible to extract information from them

- Plugins

  - some clusters use external `exec` plugins

  - these plugins typically use API keys to generate or obtain tokens

  - example: the AWS EKS authenticator works this way

---

class: extra-details

## Token authentication in practice

- We are going to list existing service accounts

- Then we will extract the token for a given service account

- And we will use that token to authenticate with the API

---

class: extra-details

## Listing service accounts

.lab[

- The resource name is `serviceaccount` or `sa` for short:
  ```bash
  kubectl get sa
  ```

]

There should be just one service account in the default namespace: `default`.

---

class: extra-details

## Finding the secret

.lab[

- List the secrets for the `default` service account:
  ```bash
  kubectl get sa default -o yaml
  SECRET=$(kubectl get sa default -o json | jq -r .secrets[0].name)
  ```

]

It should be named `default-token-XXXXX`.

---

class: extra-details

## Extracting the token

- The token is stored in the secret, wrapped with base64 encoding

.lab[

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

.lab[

- Find the ClusterIP for the `kubernetes` service:
  ```bash
  kubectl get svc kubernetes
  API=$(kubectl get svc kubernetes -o json | jq -r .spec.clusterIP)
  ```

- Connect without the token:
  ```bash
  curl -k https://$API
  ```

- Connect with the token:
  ```bash
  curl -k -H "Authorization: Bearer $TOKEN" https://$API
  ```

]

---

class: extra-details

## Results

- In both cases, we will get a "Forbidden" error

- Without authentication, the user is `system:anonymous`

- With authentication, it is shown as `system:serviceaccount:default:default`

- The API "sees" us as a different user

- But neither user has any rights, so we can't do nothin'

- Let's change that!

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

class: extra-details

## Listing all possible verbs

- The Kubernetes API is self-documented

- We can ask it which resources, subresources, and verb exist

- One way to do this is to use:

  - `kubectl get --raw /api/v1` (for core resources with `apiVersion: v1`)

  - `kubectl get --raw /apis/<group>/<version>` (for other resources)

- The JSON response can be formatted with e.g. `jq` for readability

---

class: extra-details

## Examples

- List all verbs across all `v1` resources

  ```bash
  kubectl get --raw /api/v1 | jq -r .resources[].verbs[] | sort -u
  ```

- List all resources and subresources in `apps/v1`

  ```bash
  kubectl get --raw /apis/apps/v1 | jq -r .resources[].name
  ```

- List which verbs are available on which resources in `networking.k8s.io`

  ```bash
  kubectl get --raw /apis/networking.k8s.io/v1 | \
          jq -r '.resources[] | .name + ": " + (.verbs | join(", "))'
  ```

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

## In practice

- We are going to run a pod

- This pod will use the default service account of its namespace

- We will check our API permissions

  (there shouldn't be any)

- Then we will bind a role to the service account

- We will check that we were granted the corresponding permissions

---

## Running a pod

- We'll use [Nixery](https://nixery.dev/) to run a pod with `curl` and `kubectl`

- Nixery automatically generates images with the requested packages

.lab[

- Run our pod:
  ```bash
  kubectl run eyepod --rm -ti --restart=Never \
          --image nixery.dev/shell/curl/kubectl -- bash
  ```

]

---

## Checking our permissions

- Normally, at this point, we don't have any API permission

.lab[

- Check our permissions with `kubectl`:
  ```bash
  kubectl get pods
  ```

]

- We should get a message telling us that our service account
  doesn't have permissions to list "pods" in the current namespace

- We can also make requests to the API server directly

  (use `kubectl -v6` to see the exact request URI!)

---

## Binding a role to the service account

- Binding a role = creating a *rolebinding* object

- We will call that object `can-view`

  (but again, we could call it `view` or whatever we like)

.lab[

- Create the new role binding:
  ```bash
  kubectl create rolebinding can-view \
          --clusterrole=view \
          --serviceaccount=default:default
  ```

]

It's important to note a couple of details in these flags...

---

## Roles vs Cluster Roles

- We used `--clusterrole=view`

- What would have happened if we had used `--role=view`?

  - we would have bound the role `view` from the local namespace
    <br/>(instead of the cluster role `view`)

  - the command would have worked fine (no error)

  - but later, our API requests would have been denied

- This is a deliberate design decision

  (we can reference roles that don't exist, and create/update them later)

---

## Users vs Service Accounts

- We used `--serviceaccount=default:default`

- What would have happened if we had used `--user=default:default`?

  - we would have bound the role to a user instead of a service account

  - again, the command would have worked fine (no error)

  - ...but our API requests would have been denied later

- What's about the `default:` prefix?

  - that's the namespace of the service account

  - yes, it could be inferred from context, but... `kubectl` requires it

---

## Checking our new permissions

- We should be able to *view* things, but not to *edit* them

.lab[

- Check our permissions with `kubectl`:
  ```bash
  kubectl get pods
  ```

- Try to create something:
  ```bash
  kubectl create deployment can-i-do-this --image=nginx
  ```

- Exit the container with `exit` or `^D`

<!-- ```key ^D``` -->

]

---

class: extra-details

## `kubectl run --serviceaccount`

- `kubectl run` also has a `--serviceaccount` flag

- ...But it's supposed to be deprecated "soon"

  (see [kubernetes/kubernetes#99732](https://github.com/kubernetes/kubernetes/pull/99732) for details)

- It's possible to specify the service account with an override:
  ```bash
  kubectl run my-pod -ti --image=alpine --restart=Never \
          --overrides='{ "spec": { "serviceAccountName" : "my-service-account" } }'
  ```

---

## `kubectl auth` and other CLI tools

- The `kubectl auth can-i` command can tell us:

  - if we can perform an action

  - if someone else can perform an action

  - what actions we can perform

- There are also other very useful tools to work with RBAC

- Let's do a quick review!

---

## `kubectl auth can-i dothis onthat`

- These commands will give us a `yes`/`no` answer:

  ```bash
  kubectl auth can-i list nodes
  kubectl auth can-i create pods
  kubectl auth can-i get pod/name-of-pod
  kubectl auth can-i get /url-fragment-of-api-request/
  kubectl auth can-i '*' services
  kubectl auth can-i get coffee
  kubectl auth can-i drink coffee
  ```

- The RBAC system is flexible

- We can check permissions on resources that don't exist yet (e.g. CRDs)

- We can check permissions for arbitrary actions

---

## `kubectl auth can-i ... --as someoneelse`

- We can check permissions on behalf of other users

  ```bash
  kubectl auth can-i list nodes \
          --as some-user
  kubectl auth can-i list nodes \
          --as system:serviceaccount:<namespace>:<name-of-service-account>
  ```

- We can also use `--as-group` to check permissions for members of a group

- `--as` and `--as-group` leverage the *impersonation API*

- These flags can be used with many other `kubectl` commands

  (not just `auth can-i`)

---

## `kubectl auth can-i --list`

- We can list the actions that are available to us:

  ```bash
  kubectl auth can-i --list
  ```

- ... Or to someone else (with `--as SomeOtherUser`)

- This is very useful to check users or service accounts for overly broad permissions

  (or when looking for ways to exploit a security vulnerability!)

- To learn more about Kubernetes attacks and threat models around RBAC:

  📽️ [Hacking into Kubernetes Security for Beginners](https://www.youtube.com/watch?v=mLsCm9GVIQg)
  by [Ellen Körbes](https://twitter.com/ellenkorbes)
  and [Tabitha Sable](https://twitter.com/TabbySable)

---

class: extra-details

## Other useful tools

- For auditing purposes, sometimes we want to know who can perform which actions

- There are a few tools to help us with that, available as `kubectl` plugins:

  - `kubectl who-can` / [kubectl-who-can](https://github.com/aquasecurity/kubectl-who-can) by Aqua Security

  - `kubectl access-matrix` / [Rakkess (Review Access)](https://github.com/corneliusweig/rakkess) by Cornelius Weig

  - `kubectl rbac-lookup` / [RBAC Lookup](https://github.com/FairwindsOps/rbac-lookup) by FairwindsOps

  - `kubectl rbac-tool` / [RBAC Tool](https://github.com/alcideio/rbac-tool) by insightCloudSec

- `kubectl` plugins can be installed and managed with `krew`

- They can also be installed and executed as standalone programs

---

class: extra-details

## Where does this `view` role come from?

- Kubernetes defines a number of ClusterRoles intended to be bound to users

- `cluster-admin` can do *everything* (think `root` on UNIX)

- `admin` can do *almost everything* (except e.g. changing resource quotas and limits)

- `edit` is similar to `admin`, but cannot view or edit permissions

- `view` has read-only access to most resources, except permissions and secrets

*In many situations, these roles will be all you need.*

*You can also customize them!*

---

class: extra-details

## Customizing the default roles

- If you need to *add* permissions to these default roles (or others),
  <br/>
  you can do it through the [ClusterRole Aggregation](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#aggregated-clusterroles) mechanism

- This happens by creating a ClusterRole with the following labels:
  ```yaml
    metadata:
      labels:
        rbac.authorization.k8s.io/aggregate-to-admin: "true"
        rbac.authorization.k8s.io/aggregate-to-edit: "true"
        rbac.authorization.k8s.io/aggregate-to-view: "true"
  ```

- This ClusterRole permissions will be added to `admin`/`edit`/`view` respectively

---

class: extra-details

## When should we use aggregation?

- By default, CRDs aren't included in `view` / `edit` / etc.

  (Kubernetes cannot guess which one are security sensitive and which ones are not)

- If we edit `view` / `edit` / etc directly, our edits will conflict

  (imagine if we have two CRDs and they both provide a custom `view` ClusterRole)

- Using aggregated roles lets us enrich the default roles without touching them

---

class: extra-details

## How aggregation works

- The corresponding roles will have `aggregationRules` like this:

   ```yaml
    aggregationRule:
      clusterRoleSelectors:
      - matchLabels:
          rbac.authorization.k8s.io/aggregate-to-view: "true"
   ```

- We can define our own custom roles with their own aggregation rules

---

class: extra-details

## Where do our permissions come from?

- When interacting with the Kubernetes API, we are using a client certificate

- We saw previously that this client certificate contained:

  `CN=kubernetes-admin` and `O=system:masters`

- Let's look for these in existing ClusterRoleBindings:
  ```bash
  kubectl get clusterrolebindings -o yaml |
    grep -e kubernetes-admin -e system:masters
  ```

  (`system:masters` should show up, but not `kubernetes-admin`.)

- Where does this match come from?

---

class: extra-details

## The `system:masters` group

- If we eyeball the output of `kubectl get clusterrolebindings -o yaml`, we'll find out!

- It is in the `cluster-admin` binding:
  ```bash
  kubectl describe clusterrolebinding cluster-admin
  ```

- This binding associates `system:masters` with the cluster role `cluster-admin`

- And the `cluster-admin` is, basically, `root`:
  ```bash
  kubectl describe clusterrole cluster-admin
  ```

---

## `list` vs. `get`

⚠️ `list` grants read permissions to resources!

- It's not possible to give permission to list resources without also reading them

- This has implications for e.g. Secrets

  (if a controller needs to be able to enumerate Secrets, it will be able to read them)

???

:EN:- Authentication and authorization in Kubernetes
:EN:- Authentication with tokens and certificates
:EN:- Authorization with RBAC (Role-Based Access Control)
:EN:- Restricting permissions with Service Accounts
:EN:- Working with Roles, Cluster Roles, Role Bindings, etc.

:FR:- Identification et droits d'accès dans Kubernetes
:FR:- Mécanismes d'identification par jetons et certificats
:FR:- Le modèle RBAC *(Role-Based Access Control)*
:FR:- Restreindre les permissions grâce aux *Service Accounts*
:FR:- Comprendre les *Roles*, *Cluster Roles*, *Role Bindings*, etc.
