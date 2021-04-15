# CI/CD with GitLab

- In this section, we will see how to set up a CI/CD pipeline with GitLab

  (using a "self-hosted" GitLab; i.e. running on our Kubernetes cluster)

- The big picture:

  - each time we push code to GitLab, it will be deployed in a staging environment

  - each time we push the `production` tag, it will be deployed in production

---

## Disclaimers

- We'll use GitLab here as an exemple, but there are many other options

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

## Install GitLab itself

- We will deploy GitLab with its official Helm chart

- It will still require a bunch of parameters and customization

- Brace!

---

## Installing the GitLab chart

```bash
helm repo add gitlab https://charts.gitlab.io/
DOMAIN=`cloudnative.party`
ISSUER=letsencrypt-production
helm upgrade --install gitlab gitlab/gitlab \
    --create-namespace --namespace gitlab \
    --set global.hosts.domain=$DOMAIN \
    --set certmanager.install=false \
    --set nginx-ingress.enabled=false \
    --set global.ingress.class=traefik \
    --set global.ingress.provider=traefik \
    --set global.ingress.configureCertmanager=false \
    --set global.ingress.annotations."cert-manager\.io/cluster-issuer"=$ISSUER \
    --set gitlab.webservice.ingress.tls.secretName=gitlab-gitlab-tls \
    --set registry.ingress.tls.secretName=gitlab-registry-tls \
    --set minio.ingress.tls.secretName=gitlab-minio-tls
```

😰 Can we talk about all these parameters?

---

## Breaking down all these parameters

- `certmanager.install=false`

  do not install cert-manager, we already have it

- `nginx-ingress.enabled=false`

  do not install the NGINX ingress controller, we already have Traefik

- `global.ingress.class=traefik`, `global.ingress.provider=traefik`

  these merely enable creation of Ingress resources

- `global.ingress.configureCertmanager=false`

  do not create a cert-manager Issuer or ClusterIssuer, we have ours

---

## More parameters

- `global.ingress.annotations."cert-manager\.io/cluster-issuer"=$ISSUER`

  this annotation tells cert-manager to automatically issue certs

- `gitlab.webservice.ingress.tls.secretName=gitlab-gitlab-tls`,
  <br/>
  `registry.ingress.tls.secretName=gitlab-registry-tls`,
  <br/>
  `minio.ingress.tls.secretName=gitlab-minio-tls`

  these annotations enable TLS in the Ingress controller

---

## Wait for GitLab to come up

- Let's watch what's happening in the GitLab namespace:
  ```bash
  watch kubectl get all --namespace gitlab
  ```

- We want to wait for all the Pods to be "Running" or "Completed"

- This will take a few minutes (10-15 minutes for me)

- Don't worry if you see Pods crashing and restarting

  (it happens when they are waiting on a dependency which isn't up yet)

---

## Things that could go wrong

- Symptom: Pods remain "Pending" or "ContainerCreating" for a while

- Investigate these pods (with `kubectl describe pod ...`)

- Also look at events:
  ```bash
    kubectl get events \
      --field-selector=type=Warning --sort-by=metadata.creationTimestamp
  ```

- Make sure your cluster is big enough

  (I use 3 `g6-standard-4` nodes)

---

## Log into GitLab

- First, let's check that we can connect to GitLab (with TLS):

  `https://gitlab.$DOMAIN`

- It's asking us for a login and password!

- The login is `root`, and the password is stored in a Secret:
  ```bash
    kubectl get secrets --namespace=gitlab gitlab-gitlab-initial-root-password \
      -o jsonpath={.data.password} | base64 -d
  ```

---

## Configure GitLab

- For simplicity, we're going to use that "root" user

  (but later, you can create multiple users, teams, etc.)

- First, let's add our SSH key

  (top-right user menu → settings, then SSH keys on the left)

- Then, create a project

  (using the + menu next to the search bar on top)

- Let's call it `kubecoin`

  (you can change it, but you'll have to adjust Git paths later on)

---

## Try to push our repository

- This is the repository that we're going to use:

  https://github.com/jpetazzo/kubecoin

- Let's clone that repository locally first:
  ```bash
  git clone https://github.com/jpetazzo/kubecoin
  ```

- Add our GitLab instance as a remote:
  ```bash
  git remote add gitlab git@gitlab.$DOMAIN:root/kubecoin.git
  ```

- Try to push:
  ```bash
  git push -u gitlab
  ```

---

## Connection refused?

- Normally, we get the following error:

  `port 22: Connection refused`

- Why? 🤔

--

- What does `gitlab.$DOMAIN` point to?

--

- Our Ingress Controller! (i.e. Traefik) 💡

- Our Ingress Controller has nothing to do with port 22

- So how do we solve this?

---

## Routing port 22

- Whatever is on `gitlab.$DOMAIN` needs to have the following "routing":

  - port 80 → GitLab web service

  - port 443 → GitLab web service, with TLS

  - port 22 → GitLab shell service

- Currently, Traefik is managing `gitlab.$DOMAIN`

- We are going to tell Traefik to:

  - accept connections on port 22

  - send them to GitLab

---

## TCP routing

- The technique that we are going to use is specific to Traefik

- Other Ingress Controllers may or may not have similar features

- When they have similar features, they will be enabled very differently

---

## Telling Traefik to open port 22

- Let's reconfigure Traefik:
  ```bash
    helm upgrade --install traefik traefik/traefik \
        --create-namespace --namespace traefik \
        --set "ports.websecure.tls.enabled=true" \
        --set "providers.kubernetesIngress.publishedService.enabled=true" \
        --set "ports.ssh.port=2222" \
        --set "ports.ssh.exposedPort=22" \
        --set "ports.ssh.expose=true" \
        --set "ports.ssh.protocol=TCP"
  ```

- This creates a new "port" on Traefik, called "ssh", listening on port 22

- Internally, Traefik listens on port 2222 (for permission reasons)

- Note: Traefik docs also call these ports "entrypoints"

  (these entrypoints are totally unrelated to the `ENTRYPOINT` in Dockerfiles)

---

## Knocking on port 22

- What happens if we try to connect to that port 22 right now?
  ```bash
  curl gitlab.$DOMAIN:22
  ```

- We hit GitLab's web service!

- We need to tell Traefik what to do with connections to that port 22

- For that, we will create a "TCP route"

---

## Traefik TCP route

The following custom resource tells Traefik to route the `ssh` port that we
created earlier, to the `gitlab-gitlab-shell` service belonging to GitLab.

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRouteTCP
metadata:
  name: gitlab-shell
  namespace: gitlab
spec:
  entryPoints:
  - ssh
  routes:
  - match: HostSNI(\`*`)
    services:
    - name: gitlab-gitlab-shell
      port: 22
```

The `HostSNI` wildcard is the magic option to define a "default route".

---

## Creating the TCP route

Since our manifest has backticks, we must pay attention to quoting:

```bash
kubectl apply -f- << "EOF"
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRouteTCP
metadata:
  name: gitlab-shell
  namespace: gitlab
spec:
  entryPoints:
  - ssh
  routes:
  - match: HostSNI(\`*`)
    services:
    - name: gitlab-gitlab-shell
      port: 22
EOF
```

---

## Knocking on port 22, again

- Let's see what happens if we try port 22 now:
  ```bash
  curl gitlab.$DOMAIN:22
  ```

- This should tell us something like `Received HTTP/0.9 when not allowed`

  (because we're no longer talking to an HTTP server, but to SSH!)

- Try with SSH:
  ```bash
  ssh git@gitlab.$DOMAIN
  ```

- After accepting the key fingerprint, we should see `Welcome to GitLab, @root!`

---

## Pushing again

- Now we can try to push our repository again:
  ```bash
  git push -u gitlab
  ```

- Reload the project page in GitLab

- We should see our repository!

---

## CI/CD

- Click on the CI/CD tab on the left
 
  (the one with the shuttle / space rocket icon)

- Our pipeline was detected...

- But it failed 😕

- Let's click on one of the failed jobs

- This is a permission issue!

---

## Fixing permissions

- GitLab needs to do a few of things in our cluster:

  - create Pods to build our container images with BuildKit

  - create Namespaces to deploy staging and production versions of our app

  - create and update resources in these Namespaces

- For the time being, we're going to grant broad permissions

  (and we will revisit and discuss what to do later)

---

## Granting permissions

- Let's give `cluster-admin` permissions to the GitLab ServiceAccount:
  ```bash
    kubectl create clusterrolebinding gitlab \
        --clusterrole=cluster-admin --serviceaccount=gitlab:default
  ```

- Then retry the CI/CD pipeline

- The build steps will now succeed; but the deploy steps will fail

- We need to set the `REGISTRY_USER` and `REGISTRY_PASSWORD` variables

- Let's explain what this is about!

---

## GitLab container registry access

- A registry access token is created for the duration of the CI/CD pipeline

  (it is exposed through the `$CI_JOB_TOKEN` environment variable)

- This token gives access only to a specific repository in the registry

- It is valid only during the execution of the CI/CD pipeline

- We can (and we do!) use it to *push* images to the registry

- We cannot use it to *pull* images when running in staging or production

  (because Kubernetes might need to pull images *after* the token expires)

- We need to create a separate read-only registry access token

---

## Creating the registry access token

- Let's go to "Settings" (the cog wheel on the left) / "Access Tokens"

- Create a token with `read_registry` permission

- Save the token name and the token value

- Then go to "Settings" / "CI/CD"

- In the "Variables" section, add two variables:

  - `REGISTRY_USER` → token name
  - `REGISTRY_PASSWORD` → token value

- Make sure that they are **not** protected!

  (otherwise, they won't be available in non-default tags and branches)

---

## Trying again

- Go back to the CI/CD pipeline view, and hit "Retry"

- The deploy stage should now work correctly! 🎉

---

## Our CI/CD pipeline

- Let's have a look at the [.gitlab-ci.yml](https://github.com/jpetazzo/kubecoin/blob/107dac5066087c52747e557babc97e57f42dd71d/.gitlab-ci.yml) file

- We have multiple *stages*:

  - lint (currently doesn't do much, it's mostly as an example)

  - build (currently uses BuildKit)

  - deploy

- "Deploy" behaves differently in staging and production

- Let's investigate that!

---

## Staging vs production

- In our pipeline, "production" means "a tag or branch named `production`"

  (see the `except:` and `only:` sections)

- Everything else is "staging"

- In "staging":

  - we build and push images
  - we create a staging Namespace and deploy a copy of the app there

- In "production":

  - we do not build anything
  - we deploy (or update) a copy of the app in the production Namespace

---

## Namespace naming

- GitLab will create Namespaces named `gl-<user>-<project>-<hash>`

- At the end of the deployment, the web UI will be available at:

  `http://<user>-<project>-<githash>-gitlab.<domain>`

- The "production" Namespace will be `<user>-<project>`

- And it will be available on its own domain as well:

  `http://<project>-<githash>-gitlab.<domain>`

---

## Production

- `git tag -f production && git push -f --tags`

- Our CI/CD pipeline will deploy on the production URL

  (`http://<user>-<project>-gitlab.<domain>`)

- It will do it *only* if that same git commit was pushed to staging first

  (because the "production" pipeline skips the build phase)

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

## Why not use GitLab's Kubernetes integration?

- "All-in-one" approach

  (deploys its own Ingress, cert-manager, Prometheus, and much more)

- I wanted to show you something flexible and customizable instead

- But feel free to explore it now that we have shown the basics!

???

:EN:- CI/CD with GitLab
:FR:- CI/CD avec GitLab
