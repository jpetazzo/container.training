# Securing the control plane

- Many components accept connections (and requests) from others:

  - API server

  - etcd

  - kubelet

- We must secure these connections:

  - to deny unauthorized requests

  - to prevent eavesdropping secrets, tokens, and other sensitive information

- Disabling authentication and/or authorization is **strongly discouraged**

  (but it's possible to do it, e.g. for learning / troubleshooting purposes)

---

## Authentication and authorization

- Authentication (checking "who you are") is done with mutual TLS

 (both the client and the server need to hold a valid certificate)

- Authorization (checking "what you can do") is done in different ways

  - the API server implements a sophisticated permission logic (with RBAC)
  
  - some services will defer authorization to the API server (through webhooks)

  - some services require a certificate signed by a particular CA / sub-CA

---

## In practice

- We will review the various communication channels in the control plane

- We will describe how they are secured

- When TLS certificates are used, we will indicate:

  - which CA signs them

  - what their subject (CN) should be, when applicable

- We will indicate how to configure security (client- and server-side)

---

## etcd peers

- Replication and coordination of etcd happens on a dedicated port

  (typically port 2380; the default port for normal client connections is 2379)

- Authentication uses TLS certificates with a separate sub-CA

  (otherwise, anyone with a Kubernetes client certificate could access etcd!)

- The etcd command line flags involved are:

   `--peer-client-cert-auth=true` to activate it

   `--peer-cert-file`, `--peer-key-file`, `--peer-trusted-ca-file`

---

## etcd clients

- The only¹ thing that connects to etcd is the API server

- Authentication uses TLS certificates with a separate sub-CA

  (for the same reasons as for etcd inter-peer authentication)

- The etcd command line flags involved are:

  `--client-cert-auth=true` to activate it

  `--trusted-ca-file`, `--cert-file`, `--key-file`

- The API server command line flags involved are:

  `--etcd-cafile`, `--etcd-certfile`, `--etcd-keyfile`

.footnote[¹Technically, there is also the etcd healthcheck. Let's ignore it for now.]

---

## API server clients

- The API server has a sophisticated authentication and authorization system

- For connections coming from other components of the control plane:

  - authentication uses certificates (trusting the certificates' subject or CN)

  - authorization uses whatever mechanism is enabled (most oftentimes, RBAC)

- The relevant API server flags are:

  `--client-ca-file`, `--tls-cert-file`, `--tls-private-key-file`

- Each component connecting to the API server takes a `--kubeconfig` flag

  (to specify a kubeconfig file containing the CA cert, client key, and client cert)

- Yes, that kubeconfig file follows the same format as our `~/.kube/config` file!

---

## Kubelet and API server

- Communication between kubelet and API server can be established both ways

- Kubelet → API server:

  - kubelet registers itself ("hi, I'm node42, do you have work for me?")

  - connection is kept open and re-established if it breaks

  - that's how the kubelet knows which pods to start/stop

- API server → kubelet:

  - used to retrieve logs, exec, attach to containers

---

## Kubelet → API server

- Kubelet is started with `--kubeconfig` with API server information

- The client certificate of the kubelet will typically have:

  `CN=system:node:<nodename>` and groups `O=system:nodes`

- Nothing special on the API server side

  (it will authenticate like any other client)

---

## API server → kubelet

- Kubelet is started with the flag `--client-ca-file`

  (typically using the same CA as the API server)

- API server will use a dedicated key pair when contacting kubelet

  (specified with `--kubelet-client-certificate` and `--kubelet-client-key`)

- Authorization uses webhooks

  (enabled with `--authorization-mode=Webhook` on kubelet)

- The webhook server is the API server itself

  (the kubelet sends back a request to the API server to ask, "can this person do that?")

---

## Scheduler

- The scheduler connects to the API server like an ordinary client

- The certificate of the scheduler will have `CN=system:kube-scheduler`

---

## Controller manager

- The controller manager is also a normal client to the API server

- Its certificate will have `CN=system:kube-controller-manager`

- If we use the CSR API, the controller manager needs the CA cert and key

  (passed with flags `--cluster-signing-cert-file` and `--cluster-signing-key-file`)

- We usually want the controller manager to generate tokens for service accounts

- These tokens deserve some details (on the next slide!)

---

## Service account tokens

- Each time we create a service account, the controller manager generates a token

- These tokens are JWT tokens, signed with a particular key

- These tokens are used for authentication with the API server

  (and therefore, the API server needs to be able to verify their integrity)

- This uses another keypair:

  - the private key (used for signature) is passed to the controller manager
    <br/>(using flags `--service-account-private-key-file` and `--root-ca-file`)

  - the public key (used for verification) is passed to the API server
    <br/>(using flag `--service-account-key-file`)

---

## kube-proxy

- kube-proxy is "yet another API server client"

- In many clusters, it runs as a Daemon Set

- In that case, it will have its own Service Account and associated permissions

- It will authenticate using the token of that Service Account

---

## Webhooks

- We mentioned webhooks earlier; how does that really work?

- The Kubernetes API has special resource types to check permissions

- One of them is SubjectAccessReview

- To check if a particular user can do a particular action on a particular resource:

  - we prepare a SubjectAccessReview object

  - we send that object to the API server

  - the API server responds with allow/deny (and optional explanations)

- Using webhooks for authorization = sending SAR to authorize each request

---

## Subject Access Review

Here is an example showing how to check if `jean.doe` can `get` some `pods` in `kube-system`:

```bash
kubectl -v9 create -f- <<EOF
apiVersion: authorization.k8s.io/v1beta1
kind: SubjectAccessReview
spec:
  user: jean.doe
  group:
  - foo
  - bar
  resourceAttributes:
    #group: blah.k8s.io
    namespace: kube-system
    resource: pods
    verb: get
    #name: web-xyz1234567-pqr89
EOF
```

???

:EN:- Control plane authentication
:FR:- Sécurisation du plan de contrôle
