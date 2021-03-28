# Amazon EKS

- Elastic Kubernetes Service

- AWS runs the Kubernetes control plane

  (all we see is an API server endpoint)

- Pods can run on any combination of:

  - EKS-managed nodes

  - self-managed nodes

  - Fargate

- Leverages and integrates with AWS services and APIs

---

## Some integrations

- Authenticate with IAM users and roles

- Associate IAM roles to Kubernetes ServiceAccounts

- Load balance traffic with ALB/ELB/NLB

- Persist data with EBS/EFS

- Label nodes with instance ID, instance type, region, AZ ...

- Pods can be "first class citizens" of VPC

---

## Pros/cons

- Fully managed control plane

- Handles deployment, upgrade, scaling of the control plane

- Available versions and features tend to lag a bit

- Doesn't fit the most demanding users

  ("demanding" starts somewhere between 100 and 1000 nodes)

---

## Good to know ...

- Some integrations are specific to EKS

  (some authentication models)

- Many integrations are *not* specific to EKS

- The Cloud Controller Manager can run outside of EKS

  (and provide LoadBalancer services, EBS volumes, and more)

---

# Provisioning clusters

- AWS console, API, CLI

- `eksctl`

- Infrastructure-as-Code

---

## AWS "native" provisioning

- AWS web console

  - click-click-click!

  - difficulty: low

- AWS API or CLI

  - must provide subnets, ARNs

  - difficulty: medium

---

## `eksctl`

- Originally developed by Weave

  (back when AWS "native" provisioning wasn't very good)

- `eksctl create cluster` just works™

- Has been "adopted" by AWS

  (is listed in official documentations)

---

## Infrastructure-as-Code

- Cloud Formation

- Terraform

  [terraform-aws-eks](https://github.com/terraform-aws-modules/terraform-aws-eks)
  by the community
  ([example](https://github.com/terraform-aws-modules/terraform-aws-eks/tree/master/examples/basic))

  [terraform-provider-aws](https://github.com/hashicorp/terraform-provider-aws)
  by Hashicorp
  ([example](https://github.com/hashicorp/terraform-provider-aws/tree/main/examples/eks-getting-started))

  [Kubestack](https://www.kubestack.com/)

---

## Node groups

- Virtually all provisioning models have a concept of "node group"

- Node group = group of similar nodes in an ASG

  - can span multiple AZ

  - can have instances of different types¹

- A cluster will need at least one node group

.footnote[¹As I understand it, to specify fallbacks if one instance type is unavailable or out of capacity.]

---

# IAM → EKS authentication

- Access EKS clusters using IAM users and roles

- No special role, permission, or policy is needed in IAM

  (but the `eks:DescribeCluster` permission can be useful, see later)

- Users and roles need to be explicitly listed in the cluster

- Configuration is done through a ConfigMap in the cluster

---

## Setting it up

- Nothing to do when creating the cluster

  (feature is always enabled)

- Users and roles are *mapped* to Kubernetes users and groups

  (through the `aws-auth` ConfigMap in `kube-system`)

- That's it!

---

## Mapping

- The `aws-auth` ConfigMap can contain two entries:

  - `mapRoles` (map IAM roles)

  - `mapUsers` (map IAM users)

- Each entry is a YAML file

- Each entry includes:

  - `rolearn` or `userarn` to map

  - `username` (as a string)

  - `groups` (as a list; can be empty)

---

## Example

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: kube-system
  name: aws-auth
data:
  mapRoles: `|`
    - rolearn: arn:aws:iam::111122223333:role/blah
      username: blah
      groups: [ devs, ops ]
  mapUsers: `|`
    - userarn: arn:aws:iam::111122223333:user/alice
      username: alice
      groups: [ system:masters ]
    - userarn: arn:aws:iam::111122223333:user/bob
      username: bob
      groups: [ system:masters ]
```

---

## Client setup

- We need either the `aws` CLI or the `aws-iam-authenticator`

- We use them as `exec` plugins in `~/.kube/config`

- Done automatically by `eksctl`

- Or manually with `aws eks update-kubeconfig`

- Discovering the address of the API server requires one IAM permission

  ```json
    "Action": [
        "eks:DescribeCluster"
    ],
    "Resource": "arn:aws:eks:<region>:<account>:cluster/<cluster-name>"
  ```

  (wildcards can be used when specifying the resource)

---

class: extra-details

## How it works

- The helper generates a token

  (with `aws eks get-token` or `aws-iam-authenticator token`)

- Note: these calls will always succeed!

  (even if AWS API keys are invalid)

- The token is used to authenticate with the Kubernetes API

- AWS' Kubernetes API server will decode and validate the token

  (and map the underlying user or role accordingly)

---

## Read The Fine Manual

https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html

---

# EKS → IAM authentication

- Access AWS services from workloads running on EKS

  (e.g.: access S3 bucket from code running in a Pod)

- This works by associating an IAM role to a K8S ServiceAccount

- There are also a few specific roles used internally by EKS

  (e.g. to let the nodes establish network configurations)

- ... We won't talk about these

---

## The big picture

- One-time setup task

  ([create an OIDC provider associated to our EKS cluster](https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html))

- Create (or update) a role with an appropriate *trust policy*

  (more on that later)

- Annotate service accounts to map them to that role

  `eks.amazonaws.com/role-arn=arn:aws:iam::111122223333:role/some-iam-role`

- Create (or re-create) pods using that ServiceAccount

- The pods can now use that role!

---

## Trust policies

- IAM roles have a *trust policy* (aka *assume role policy*)

  (cf `aws iam create-role ... --assume-role-policy-document ...`)

- That policy contains a *statement* list

- This list indicates who/what is allowed to assume (use) the role

- In the current scenario, that policy will contain something saying:

  *ServiceAccount S on EKS cluster C is allowed to use this role*

---

## Trust policy for a single ServiceAccount

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/${OIDC_PROVIDER}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${OIDC_PROVIDER}:sub":
            "system:serviceaccount:<namespace>:<service-account>"
        }
      }
    }
  ]
}
```

---

## Trust policy for multiple ServiceAccounts

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/${OIDC_PROVIDER}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringLike": {
            "${OIDC_PROVIDER}:sub": 
              ["system:serviceaccount:container-training:*"]
        }
      }
    }
  ]
}
```

---

## The little details

- When pods are created, they are processed by a mutating webhook

  (typically named `pod-identity-webhook`)

- Pods using a ServiceAccount with the right annotation get:

  - an extra token
    <br/>
    (mounted in `/var/run/secrets/eks.amazonaws.com/serviceaccount/token`)

  - a few env vars
    <br/>
    (including `AWS_WEB_IDENTITY_TOKEN_FILE` and `AWS_ROLE_ARN`)

- AWS client libraries and tooling will work this that

  (see [this list](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts-minimum-sdk.html) for supported versions)

---

# CNI

- EKS is a compliant Kubernetes implementation

  (which means we can use a wide range of CNI plugins)

- However, the recommended CNI plugin is the "AWS VPC CNI"

  (https://github.com/aws/amazon-vpc-cni-k8s)

- Pods are then "first class citizens" of AWS VPC

---

## AWS VPC CNI

- Each Pod gets an address in a VPC subnet

- No overlay network, no encapsulation, no overhead

  (other than AWS network fabric, obviously)

- Probably the fastest network option when running on AWS

- Allows "direct" load balancing (more on that later)

- Can use security groups with Pod traffic

- But: limits the number of Pods per Node

- But: more complex configuration (more on that later)

---

## Number of Pods per Node

- Each Pod gets an IP address on an ENI

  (Elastic Network Interface)

- EC2 instances can only have a limited number of ENIs

  (the exact limit depends on the instance type)

- ENIs can only have a limited number of IP addresses

  (with variations here as well)

- This gives limits of e.g. 35 pods on `t3.large`, 29 on `c5.large` ...

  (see
  [full list of limits per instance type](https://github.com/awslabs/amazon-eks-ami/blob/master/files/eni-max-pods.txt
)
  and
  [ENI/IP details](https://github.com/aws/amazon-vpc-cni-k8s/blob/master/pkg/awsutils/vpc_ip_resource_limit.go
))

---

## Limits?

- These limits might seem low

- They're not *that* low if you compute e.g. the RAM/Pod ratio

- Except if you're running lots if tiny pods

- Bottom line: do the math!

---

class: extra-details

## Pre-loading

- It can take a little while to allocate/attach an ENI

- The AWS VPC CNI can keep a few extra addresses on each Node

  (by default, one ENI worth of IP addresses)

- This is tunable if needed

  (see [the docs](https://github.com/aws/amazon-vpc-cni-k8s/blob/master/docs/eni-and-ip-target.md
) for details)

---

## Better load balancing

- The default path for inbound traffic is:

  Load balancer → NodePort → Pod

- With the AWS VPC CNI, it becomes possible to do:

  Load balancer → Pod

- More on that in the load balancing section!

---

## Configuration complexity

- The AWS VPC CNI is a very good solution when running EKS

- It brings optimized solutions to various use-cases:

  - direct load balancing
  - user authentication
  - interconnection with other infrastructure
  - etc.

- Keep in mind that all these solutions are AWS-specific

- They can require a non-trivial amount of specific configuration

- Especially when moving from a simple POC to an IAC deployment!

---

# Load Balancers

- Here be dragons!

- Multiple options, each with different pros/cons

- It's necessary to know both AWS products and K8S concepts

---

## AWS load balancers

- CLB / Classic Load Balancer (formerly known as ELB)

  - can work in L4 (TCP) or L7 (HTTP) mode
  - can do TLS unrolling
  - can't do websockets, HTTP/2, content-based routing ...

- NLB / Network Load Balancer

  - high-performance L4 load balancer with TLS support

- ALB / Application Load Balancer

  - HTTP load balancer
  - can do TLS unrolling
  - can do websockets, HTTP/2, content-based routing ...

---

## Load balancing modes

- "IP targets"

  - send traffic directly from LB to Pods

  - Pods must use the AWS VPC CNI

  - compatible with Fargate Pods

- "Instance targets"

  - send traffic to a NodePort (generally incurs an extra hop)

  - Pods can use any CNI

  - not compatible with Fargate Pods

- Each LB (Service) can use a different mode, if necessary

---

## Kubernetes load balancers

- Service (L4)

  - ClusterIP: internal load balancing
  - NodePort: external load balancing on ports >30000
  - LoadBalancer: external load balancing on the port you want
  - ExternalIP: external load balancing directly on nodes

- Ingress (L7 HTTP)

  - partial content-based routing (`Host` header, request path)
  - requires an Ingress Controller (in front)
  - works with Services (in back)

---

## Two controllers are available

- Kubernetes "in-tree" load balancer controller

  - always available
  - used by default for LoadBalancer Services
  - creates CLB by default; can also do NLB
  - can only do "instance targets"
  - can use extra CLB features (TLS, HTTP)

- AWS Load Balancer Controller (fka AWS ALB Ingress Controller)

  - optional add-on (requires additional config)
  - primarily meant to be an Ingress Controller
  - creates NLB and ALB
  - can do "instance targets" and "IP targets"
  - can also be used for LoadBalancer Services with type `nlb-ip`

- They can run side by side

---

## Which one should we use?

- AWS Load Balancer Controller supports "IP targets"

  (which means direct routing of traffic to Pods)

- It can be used as an Ingress controller

- It *seems* to be the perfect solution for EKS!

- However ...

---

## Caveats

- AWS Load Balancer Controller requires extensive configuration

  - a few hours to a few days to get it to work in a POC ...

  - a few days to a few weeks to industrialize that process?

- It's AWS-specific

- It still introduces an extra hop, even if that hop is invisible

- Other ingress controllers can have interesting features

  (canary deployment, A/B testing ...)

---

## Noteworthy annotations and docs

- `service.beta.kubernetes.io/aws-load-balancer-type: nlb-ip`

  - LoadBalancer Service with "IP targets" ([docs](https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/guide/service/nlb_ip_mode/))
  - requires AWS Load Balancer Controller

- `service.beta.kubernetes.io/aws-load-balancer-internal: "true"`

  - internal load balancer (for private VPC)

- `service.beta.kubernetes.io/aws-load-balancer-type: nlb`

  - opt for NLB instead of CLB with in-tree controller

- `service.beta.kubernetes.io/aws-load-balancer-proxy-protocol: "*"`

  - use HAProxy [PROXY protocol](https://www.haproxy.org/download/1.8/doc/proxy-protocol.txt)

---

## TLS-related annotations

- `service.beta.kubernetes.io/aws-load-balancer-ssl-cert`

  - enable TLS and use that certificate
  - example value: `arn:aws:acm:<region>:<account>:certificate/<cert-id>`

- `service.beta.kubernetes.io/aws-load-balancer-ssl-ports`

  - enable TLS *only* on the specified ports (when multiple ports are exposed)
  - example value: `"443,8443"`

- `service.beta.kubernetes.io/aws-load-balancer-ssl-negotiation-policy`

  - specify ciphers and other TLS parameters to use (see [that list](https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-security-policy-table.html))
  - example value: `"ELBSecurityPolicy-TLS-1-2-2017-01"`

---

## To HTTP(S) or not to HTTP(S)

- `service.beta.kubernetes.io/aws-load-balancer-backend-protocol`

  - can be either `http`, `https`, `ssl`, or `tcp`

  - if `https` or `ssl`: enable TLS to the backend

  - if `http` or `https`: enable HTTP `x-forwarded-for` headers (with `http` or `https`)

???

## Cluster autoscaling

## Logging

https://docs.aws.amazon.com/eks/latest/userguide/logging-using-cloudtrail.html

:EN:- Working with EKS
:EN:- Cluster and user provisioning
:EN:- Networking and load balancing

:FR:- Travailler avec EKS
:FR:- Outils de déploiement
:FR:- Intégration avec IAM
:FR:- Fonctionalités réseau
