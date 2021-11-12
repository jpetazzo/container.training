# CI/CD with GitLab

- In this section, we will see how to set up a CI/CD pipeline with GitLab

  (using a "self-hosted" GitLab; i.e. running on our Kubernetes cluster)

- The big picture:

  - each time we push code to GitLab, it will be deployed in a staging environment

  - each time we push the `production` tag, it will be deployed in production

---

## Disclaimers

- We'll use GitLab here as an example, but there are many other options

  (e.g. some combination of Argo, Harbor, Tekton ...)

- There are also hosted options

  (e.g. GitHub Actions and many others)

- We'll use a specific pipeline and workflow, but it's purely arbitrary

  (treat it as a source of inspiration, not a model to be copied!)

---

## Workflow overview

- Push code to GitLab's git server

- GitLab notices the `.gitlab-ci.yml` file, which defines our pipeline

- Our pipeline can have multiple *stages* executed sequentially

  (e.g. lint, build, test, deploy ...)

- Each stage can have multiple *jobs* executed in parallel

  (e.g. build images in parallel)

- Each job will be executed in an independent *runner* pod

---

## Pipeline overview

- Our repository holds source code, Dockerfiles, and a Helm chart

- *Lint* stage will check the Helm chart validity

- *Build* stage will build container images

  (and push them to GitLab's integrated registry)

- *Deploy* stage will deploy the Helm chart, using these images

- Pushes to `production` will deploy to "the" production namespace

- Pushes to other tags/branches will deploy to a namespace created on the fly

- We will discuss shortcomings and alternatives and the end of this chapter!

---

## Lots of requirements

- We need *a lot* of components to pull this off:

  - a domain name

  - a storage class

  - a TLS-capable ingress controller

  - the cert-manager operator

  - GitLab itself

  - the GitLab pipeline

- Wow, why?!?

---

## I find your lack of TLS disturbing

- We need a container registry (obviously!)

- Docker (and other container engines) *require* TLS on the registry

  (with valid certificates)

- A few options:

  - use a "real" TLS certificate (e.g. obtained with Let's Encrypt)

  - use a self-signed TLS certificate

  - communicate with the registry over localhost (TLS isn't required then)

---

class: extra-details

## Why not self-signed certs?

- When using self-signed certs, we need to either:

  - add the cert (or CA) to trusted certs

  - disable cert validation

- This needs to be done on *every client* connecting to the registry:

  - CI/CD pipeline (building and pushing images)

  - container engine (deploying the images)

  - other tools (e.g. container security scanner)

- It's doable, but it's a lot of hacks (especially when adding more tools!)

---

class: extra-details

## Why not localhost?

- TLS is usually not required when the registry is on localhost

- We could expose the registry e.g. on a `NodePort`

- ... And then tweak the CI/CD pipeline to use that instead

- This is great when obtaining valid certs is difficult:

  - air-gapped or internal environments (that can't use Let's Encrypt)

  - no domain name available

- Downside: the registry isn't easily or safely available from outside

  (the `NodePort` essentially defeats TLS)

---

class: extra-details

## Can we use `nip.io`?

- We will use Let's Encrypt

- Let's Encrypt has a quota of certificates per domain

  (in 2020, that was [50 certificates per week per domain](https://letsencrypt.org/docs/rate-limits/))

- So if we all use `nip.io`, we will probably run into that limit

- But you can try and see if it works!

---

## Ingress

- We will assume that we have a domain name pointing to our cluster

  (i.e. with a wildcard record pointing to at least one node of the cluster)

- We will get traffic in the cluster by leveraging `ExternalIPs` services

  (but it would be easy to use `LoadBalancer` services instead)

- We will use Traefik as the ingress controller

  (but any other one should work too)

- We will use cert-manager to obtain certificates with Let's Encrypt

---

## Other details

- We will deploy GitLab with its official Helm chart

- It will still require a bunch of parameters and customization

- We also need a Storage Class

  (unless our cluster already has one, of course)

- We suggest the [Rancher local path provisioner](https://github.com/rancher/local-path-provisioner)

---

## Setting everything up

1. `git clone https://github.com/jpetazzo/kubecoin`

2. `export EMAIL=xxx@example.com DOMAIN=awesome-kube-ci.io`

   (we need a real email address and a domain pointing to the cluster!)

3. `. setup-gitlab-on-k8s.rc`

   (this doesn't do anything, but defines a number of helper functions)

4. Execute each helper function, one after another

   (try `do_[TAB]` to see these functions)

---

## Local Storage

`do_1_localstorage`

Applies the YAML directly from Rancher's repository.

Annotate the Storage Class so that it becomes the default one.

---

## Traefik

`do_2_traefik_with_externalips`

Install the official Traefik Helm chart.

Instead of a `LoadBalancer` service, use a `ClusterIP` with `ExternalIPs`.

Automatically infer the `ExternalIPs` from `kubectl get nodes`.

Enable TLS.

---

## cert-manager

`do_3_certmanager`

Install cert-manager using their official YAML.

Easy-peasy.

---

## Certificate issuers

`do_4_issuers`

Create a couple of `ClusterIssuer` resources for cert-manager.

(One for the staging Let's Encrypt environment, one for production.)

Note: this requires to specify a valid `$EMAIL` address!

Note: if this fails, wait a bit and try again (cert-manager needs to be up).

---

## GitLab

`do_5_gitlab`

Deploy GitLab using their official Helm chart.

We pass a lot of parameters to this chart:
- the domain name to use
- disable GitLab's own ingress and cert-manager
- annotate the ingress resources so that cert-manager kicks in
- bind the shell service (git over SSH) to port 222 to avoid conflict
- use ExternalIPs for that shell service

Note: on modest cloud instances, it can take 10 minutes for GitLab to come up.

We can check the status with `kubectl get pods --namespace=gitlab`

---

## Log into GitLab and configure it

`do_6_showlogin`

This will get the GitLab root password (stored in a Secret).

Then we need to:
- log into GitLab
- add our SSH key (top-right user menu → settings, then SSH keys on the left)
- create a project (using the + menu next to the search bar on top)
- go to project configuration (on the left, settings → CI/CD)
- add a `KUBECONFIG` file variable with the content of our `.kube/config` file
- go to settings → access tokens to create a read-only registry token
- add variables `REGISTRY_USER` and `REGISTRY_PASSWORD` with that token
- push our repo (`git remote add gitlab ...` then `git push gitlab ...`)

---

## Monitoring progress and troubleshooting

- Click on "CI/CD" in the left bar to view pipelines

- If you see a permission issue mentioning `system:serviceaccount:gitlab:...`:

  *make sure you did set `KUBECONFIG` correctly!*

- GitLab will create namespaces named `gl-<user>-<project>`

- At the end of the deployment, the web UI will be available on some unique URL

  (`http://<user>-<project>-<githash>-gitlab.<domain>`)

---

## Production

- `git tag -f production && git push -f --tags`

- Our CI/CD pipeline will deploy on the production URL

  (`http://<user>-<project>-gitlab.<domain>`)

- It will do it *only* if that same git commit was pushed to staging first

  (look in the pipeline configuration file to see how it's done!)

---

## Let's talk about build

- There are many ways to build container images on Kubernetes

- ~~And they all suck~~ Many of them have inconveniencing issues

- Let's do a quick review!

---

## Docker-based approaches

- Bind-mount the Docker socket

  - very easy, but requires Docker Engine
  - build resource usage "evades" Kubernetes scheduler
  - insecure

- Docker-in-Docker in a pod

  - requires privileged pod
  - insecure
  - approaches like rootless or sysbox might help in the future

- External build host

  - more secure
  - requires resources outside of the Kubernetes cluster

---

## Non-privileged builders

- Kaniko

  - each build runs in its own containers or pod
  - no caching by default
  - registry-based caching is possible

- BuildKit / `docker buildx`

  - can leverage Docker Engine or long-running Kubernetes worker pod
  - supports distributed, multi-arch build farms
  - basic caching out of the box
  - can also leverage registry-based caching

---

## Other approaches

- Ditch the Dockerfile!

- bazel

- jib

- ko

- etc.

---

## Discussion

- Our CI/CD workflow is just *one* of the many possibilities

- It would be nice to add some actual unit or e2e tests

- Map the production namespace to a "real" domain name

- Automatically remove older staging environments

  (see e.g. [kube-janitor](https://codeberg.org/hjacobs/kube-janitor))

- Deploy production to a separate cluster

- Better segregate permissions

  (don't give `cluster-admin` to the GitLab pipeline)

---

## Pros

- GitLab is an amazing, open source, all-in-one platform

- Available as hosted, community, or enterprise editions

- Rich ecosystem, very customizable

- Can run on Kubernetes, or somewhere else

---

## Cons

- It can be difficult to use components separately

  (e.g. use a different registry, or a different job runner)

- More than one way to configure it

  (it's not an opinionated platform)

- Not "Kubernetes-native"

  (for instance, jobs are not Kubernetes jobs)

- Job latency could be improved

*Note: most of these drawbacks are the flip side of the "pros" on the previous slide!*

???

:EN:- CI/CD with GitLab
:FR:- CI/CD avec GitLab
