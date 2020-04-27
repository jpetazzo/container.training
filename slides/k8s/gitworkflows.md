# Git-based workflows

- Deploying with `kubectl` has downsides:

  - we don't know *who* deployed *what* and *when*

  - there is no audit trail (except the API server logs)

  - there is no easy way to undo most operations

  - there is no review/approval process (like for code reviews)

- We have all these things for *code*, though

- Can we manage cluster state like we manage our source code?

---

## Reminder: Kubernetes is *declarative*

- All we do is create/change resources

- These resources have a perfect YAML representation

- All we do is manipulating these YAML representations

  (`kubectl run` generates a YAML file that gets applied)

- We can store these YAML representations in a code repository

- We can version that code repository and maintain it with best practices

  - define which branch(es) can go to qa/staging/production

  - control who can push to which branches

  - have formal review processes, pull requests ...

---

## Enabling git-based workflows

- There are a few tools out there to help us do that

- We'll see demos of two of them: [Flux] and [Gitkube]

- There are *many* other tools, some of them with even more features

- There are also *many* integrations with popular CI/CD systems

  (e.g.: GitLab, Jenkins, ...)

[Flux]: https://www.weave.works/oss/flux/
[Gitkube]: https://gitkube.sh/

---

## Flux overview

- We put our Kubernetes resources as YAML files in a git repository

- Flux polls that repository regularly (every 5 minutes by default)

- The resources described by the YAML files are created/updated automatically

- Changes are made by updating the code in the repository

---

## Preparing a repository for Flux

- We need a repository with Kubernetes YAML files

- I have one: https://github.com/jpetazzo/kubercoins

- Fork it to your GitHub account

- Create a new branch in your fork; e.g. `prod`

  (e.g. by adding a line in the README through the GitHub web UI)

- This is the branch that we are going to use for deployment

---

## Setting up Flux

- Clone the Flux repository:
  ```
  git clone https://github.com/fluxcd/flux
  ```

- Edit `deploy/flux-deployment.yaml`

- Change the `--git-url` and `--git-branch` parameters:
  ```yaml
  - --git-url=git@github.com:your-git-username/kubercoins
  - --git-branch=prod
  ```

- Apply all the YAML:
  ```
  kubectl apply -f deploy/
  ```

---

## Allowing Flux to access the repository

- When it starts, Flux generates an SSH key

- Display that key:
  ```
  kubectl logs deployment/flux | grep identity
  ```

- Then add that key to the repository, giving it **write** access

  (some Flux features require write access)

- After a minute or so, DockerCoins will be deployed to the current namespace

---

## Making changes

- Make changes (on the `prod` branch), e.g. change `replicas` in `worker`

- After a few minutes, the changes will be picked up by Flux and applied

---

## Other features

- Flux can keep a list of all the tags of all the images we're running

- The `fluxctl` tool can show us if we're running the latest images

- We can also "automate" a resource (i.e. automatically deploy new images)

- And much more!

---

## Gitkube overview

- We put our Kubernetes resources as YAML files in a git repository

- Gitkube is a git server (or "git remote")

- After making changes to the repository, we push to Gitkube

- Gitkube applies the resources to the cluster

---

## Setting up Gitkube

- Install the CLI:
  ```
  sudo curl -L -o /usr/local/bin/gitkube \
       https://github.com/hasura/gitkube/releases/download/v0.2.1/gitkube_linux_amd64
  sudo chmod +x /usr/local/bin/gitkube
  ```

- Install Gitkube on the cluster:
  ```
  gitkube install --expose ClusterIP
  ```

---

## Creating a Remote

- Gitkube provides a new type of API resource: *Remote*

  (this is using a mechanism called Custom Resource Definitions or CRD)

- Create and apply a YAML file containing the following manifest:
  ```yaml
	apiVersion: gitkube.sh/v1alpha1
	kind: Remote
	metadata:
	  name: example
	spec:
	  authorizedKeys:
	  - `ssh-rsa AAA...`
	  manifests:
	    path: "."
  ```

  (replace the `ssh-rsa AAA...` section with the content of `~/.ssh/id_rsa.pub`)

---

## Pushing to our remote

- Get the `gitkubed` IP address:
  ```
  kubectl -n kube-system get svc gitkubed
  IP=$(kubectl -n kube-system get svc gitkubed -o json | 
  	   jq -r .spec.clusterIP)
  ```

- Get ourselves a sample repository with resource YAML files:
  ```
  git clone git://github.com/jpetazzo/kubercoins
  cd kubercoins
  ```

- Add the remote and push to it:
  ```
  git remote add k8s ssh://default-example@$IP/~/git/default-example
  git push k8s master
  ```

---

## Making changes

- Edit a local file

- Commit

- Push!

- Make sure that you push to the `k8s` remote

---

## Other features

- Gitkube can also build container images for us

  (see the [documentation](https://github.com/hasura/gitkube/blob/master/docs/remote.md) for more details)

- Gitkube can also deploy Helm charts

  (instead of raw YAML files)

???

:EN:- GitOps
:FR:- GitOps
