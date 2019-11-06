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

- This is enabled in most Kubernetes deployments

- The user name is derived from the `CN` in the client certificates

- The groups are derived from the `O` fields in the client certificate

- From the point of view of the Kubernetes API, users do not exist

  (i.e. they are not stored in etcd or anywhere else)

- Users can be created (and added to groups) independently of the API

- The Kubernetes API can be set up to use your custom CA to validate client certs

---

class: extra-details

## Viewing our admin certificate

- Let's inspect the certificate we've been using all this time!

.exercise[

- This command will show the `CN` and `O` fields for our certificate:
  ```bash
  kubectl config view \
          --raw \
          -o json \
          | jq -r .users[0].user[\"client-certificate-data\"] \
          | openssl base64 -d -A \
          | openssl x509 -text \
          | grep Subject:
  ```

]

Let's break down that command together! 😅

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

## User certificates in practice

- The Kubernetes API server does not support certificate revocation

  (see issue [#18982](https://github.com/kubernetes/kubernetes/issues/18982))

- As a result, we don't have an easy way to terminate someone's access

  (if their key is compromised, or they leave the organization)

- Option 1: re-create a new CA and re-issue everyone's certificates 
  <br/>
  → Maybe OK if we only have a few users; no way otherwise

- Option 2: don't use groups; grant permissions to individual users
  <br/>
  → Inconvenient if we have many users and teams; error-prone

- Option 3: issue short-lived certificates (e.g. 24 hours) and renew them often
  <br/>
  → This can be facilitated by e.g. Vault or by the Kubernetes CSR API

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

- We are going to create a service account

- We will use a default cluster role (`view`)

- We will bind together this role and this service account

- Then we will run a pod using that service account

- In this pod, we will install `kubectl` and check our permissions

---

## Creating a service account

- We will call the new service account `viewer`

  (note that nothing prevents us from calling it `view`, like the role)

.exercise[

- Create the new service account:
  ```bash
  kubectl create serviceaccount viewer
  ```

- List service accounts now:
  ```bash
  kubectl get serviceaccounts
  ```

]

---

## Binding a role to the service account

- Binding a role = creating a *rolebinding* object

- We will call that object `viewercanview`

  (but again, we could call it `view`)

.exercise[

- Create the new role binding:
  ```bash
  kubectl create rolebinding viewercanview \
          --clusterrole=view \
          --serviceaccount=default:viewer
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

- We used `--serviceaccount=default:viewer`

- What would have happened if we had used `--user=default:viewer`?

  - we would have bound the role to a user instead of a service account

  - again, the command would have worked fine (no error)

  - ...but our API requests would have been denied later

- What's about the `default:` prefix?

  - that's the namespace of the service account

  - yes, it could be inferred from context, but... `kubectl` requires it

---

## Testing

- We will run an `alpine` pod and install `kubectl` there

.exercise[

- Run a one-time pod:
  ```bash
  kubectl run eyepod --rm -ti --restart=Never \
          --serviceaccount=viewer \
          --image alpine
  ```

- Install `curl`, then use it to install `kubectl`:
  ```bash
  apk add --no-cache curl
  URLBASE=https://storage.googleapis.com/kubernetes-release/release
  KUBEVER=$(curl -s $URLBASE/stable.txt)
  curl -LO $URLBASE/$KUBEVER/bin/linux/amd64/kubectl
  chmod +x kubectl
  ```

]

---

## Running `kubectl` in the pod

- We'll try to use our `view` permissions, then to create an object

.exercise[

- Check that we can, indeed, view things:
  ```bash
  ./kubectl get all
  ```

- But that we can't create things:
  ```
  ./kubectl create deployment testrbac --image=nginx
  ```

- Exit the container with `exit` or `^D`

<!-- ```keys ^D``` -->

]

---

## Testing directly with `kubectl`

- We can also check for permission with `kubectl auth can-i`:
  ```bash
  kubectl auth can-i list nodes
  kubectl auth can-i create pods
  kubectl auth can-i get pod/name-of-pod
  kubectl auth can-i get /url-fragment-of-api-request/
  kubectl auth can-i '*' services
  ```

- And we can check permissions on behalf of other users:
  ```bash
  kubectl auth can-i list nodes \
          --as some-user
  kubectl auth can-i list nodes \
          --as system:serviceaccount:<namespace>:<name-of-service-account>
  ```

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

- This is particulary useful when using CustomResourceDefinitions

  (since Kubernetes cannot guess which resources are sensitive and which ones aren't)

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

class: extra-details

## Figuring out who can do what

- For auditing purposes, sometimes we want to know who can perform an action

- There are a few tools to help us with that

  - [kubectl-who-can](https://github.com/aquasecurity/kubectl-who-can) by Aqua Security

  - [Review Access (aka Rakkess)](https://github.com/corneliusweig/rakkess)

- Both are available as standalone programs, or as plugins for `kubectl`

  (`kubectl` plugins can be installed and managed with `krew`)
