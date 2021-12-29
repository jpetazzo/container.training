## Accessing our EKS cluster

- We also have a shared EKS cluster

- With individual IAM users

- Let's connect to this cluster!

---

## What we need

- `kubectl` (obviously!)

- `aws` CLI (recent-ish version)

  (or `aws` CLI + `aws-iam-authenticator` plugin)

- AWS API access key and secret access key

- AWS region

- EKS cluster name

---

## Setting up AWS credentials

- There are many ways to do this

- We're going to use environment variables

- You're welcome to use whatever you like (e.g. AWS profiles)

.lab[

- Set the AWS region, API access key, and secret key:
  ```bash
  export AWS_DEFAULT_REGION=`us-east-2`
  export AWS_ACCESS_KEY_ID=`AKI...`
  export AWS_SECRET_ACCESS_KEY=`xyz123...`
  ```

- Check that the AWS API recognizes us:
  ```bash
  aws sts get-caller-identity
  ```

]

---

## Updating our kubeconfig file

- Now we can use the AWS CLI to:

  - obtain the Kubernetes API address

  - register it in our kubeconfig file

.lab[

- Update our kubeconfig file:
  ```bash
  aws eks update-kubeconfig --name `fancy-clustername-1234`
  ```

- Run some harmless command:
  ```bash
  kubectl version
  ```

]

---

## Our resources

- We have the following permissions:

  - `view` in the `default` namespace

  - `edit` in the `container-training` namespace

  - `admin` in our personal namespace

- Our personal namespace is our IAM user name

  (but with dots replaced with dashes)

- For instance, user `ada.lovelace` has namespace `ada-lovelace`

---

## Deploying things

- Let's deploy DockerCoins in our personal namespace!

- Expose the Web UI with a `LoadBalancer` service

???

:EN:- Working with an EKS cluster
:FR:- Travailler avec un cluster EKS
