## Connecting to wek8s

- Let's see what it entails to connect to one of our wek8s clusters

- We need an account on https://we.okta.com/

  (with access to "Dev AWS" environment)

- We need an account on https://quay.io/

  (with access to images
  [wework/okta-aws](https://quay.io/repository/wework/okta-aws)
  and
  [wework/wek8s-tools](https://quay.io/repository/wework/wek8s-tools))

- We will obtain AWS credentials through Okta

- Then, we will use these AWS credentials to obtain Kubernetes credentials

  (because the wek8s cluster we will connect to is using AWS EKS under the hood)

.warning[These instructions are up-to-date as of May 2019, but may change in the future.]

---

## Obtaining AWS credentials

- We will use okta-aws to obtain our AWS credentials

- For convenience, we will use a pre-built okta-aws container

.warning[If we already have credentials in `~/.aws`, this may overwrite them!]

.exercise[

- Run okta-aws to obtain AWS credentials and store them in `~/.aws`:
  ```bash
    docker run -it --rm -v ~/.aws:/package/.aws quay.io/wework/okta-aws
  ```

- Select `Dev` environment at the first prompt

- Enter Okta email, password, and MFA code

]

---

## Verifying account and role

The last lines of output of okta-aws will confirm which account we logged into.

For the `Dev` account, this should look like this:

```
Account: 681484253316
Role: AWS-Admin
Profile: saml
```

... And a few files have been updated in `~/.aws`, including `~/.aws/credentials`.

Q: How did the container update `~/.aws` on our machine?

A: Because we mounted that directory into the container with `-v`.

---

## Running wek8s-tools

- Two more steps are necessary to obtain Kubernetes cluster credentials

- For simplicity, we are going to use a "Swiss Army Knife" image, wek8s-tools

- This image contains tools to obtain the Kubernetes credentials + many others

  (including kubectl, helm, ...)

.exercise[

- Start a container using the the wek8s-tools image:
  ```bash
  docker run --rm -v ~/.aws:/root/.aws -it quay.io/wework/wek8s-tools:0.3.2 sh
  ```

]

*We are using the `-v` option again, to mount our fresh AWS credentials into this container.*

---

## Generating kubeconfig

- The next step is to generate a kubeconfig file with:

  - the address of the wek8s cluster we want to use

  - instructions to use the AWS IAM authenticator plugin

- This is done with the `deploy_helper` binary

.exercise[

- Generate the kubeconfig file:
  ```bash
  deploy_helper fetch_reqs --env wek8s-phoenix --namespace k8s-training
  ```

]

We now have a `~kube/config` file (in the container).

---

## Using the cluster

- Let's get a shell on this cluster!

.exercise[

- Run a one-time Pod with an Alpine container:
  ```bash
  kubectl -n k8s-training run --restart=Never --rm -it test-$RANDOM --image=alpine
  ```

- Find out the node's IP address:
  ```bash
  apk add curl
  curl https://canihazip.com/s
  ```

- Exit when done

]

---

## Using local tools

.warning[Do not run the commands in this slide! This is not an exercise ☺]

- What if we wanted to use our local tools, instead of the wek8s-tools image?

- First, we would need to install the AWS IAM authenticator plugin

  (see [AWS EKS documentation](https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html) for instructions)

- Then, we would need to get the kubeconfig file:
  ```bash
    docker run --rm -v ~/.aws:/root/.aws -v ~/.kube-wek8s:/root/.kube \
           quay.io/wework/wek8s-tools:0.3.2 \
           deploy_helper fetch_reqs --env wek8s-phoenix --namespace k8s-training
  ```

- This would generate the file `~/.kube-wek8s/config`

---

## Permission issues

.warning[Do not run the commands in this slide! This is not an exercise ☺]

- If you use Docker Desktop (on Windows or macOS), you should be set

- Otherwise (on Linux or Docker Toolbox) you will need to fix permissions:
  ```bash
  chown -R $USER ~/.kube-wek8s
  ```

---

## Connecting to wek8s with local tools

.warning[Do not run the commands in this slide! This is not an exercise ☺]

- We would need to tell kubectl (and other tools) to use the file we generated:
  ```bash
  export KUBECONFIG=~/.kube-wek8s/config
  ```

- Then we could do some simple commands to test the connection:
  ```bash
  kubectl get version
  kubectl get svc -n default kubernetes
  ```

---

## Deploying DockerCoins on wek8s

.warning[Do not run the commands in this slide! This is not an exercise ☺]

- We could deploy DockerCoins like this:
  ```bash
  git clone https://github.com/jpetazzo/kubercoins
  kubectl -n k8s-training apply -f kubercoins
  ```

- To access the web UI, we would need an Ingress

  (more on that later)

- Rather than applying YAML directly, we would use Helm Charts

  (more on that later)
