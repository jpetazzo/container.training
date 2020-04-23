# Last words

- Congratulations!

- We learned a lot about Kubernetes, its internals, its advanced concepts

--

- That was just the easy part

- The hard challenges will revolve around *culture* and *people*

--

- ... What does that mean?

---

## Running an app involves many steps

- Write the app

- Tests, QA ...

- Ship *something* (more on that later)

- Provision resources (e.g. VMs, clusters)

- Deploy the *something* on the resources

- Manage, maintain, monitor the resources

- Manage, maintain, monitor the app

- And much more

---

## Who does what?

- The old "devs vs ops" division has changed

- In some organizations, "ops" are now called "SRE" or "platform" teams

  (and they have very different sets of skills)

- Do you know which team is responsible for each item on the list on the previous page?

- Acknowledge that a lot of tasks are outsourced

  (e.g. if we add "buy/rack/provision machines" in that list)

---

## What do we ship?

- Some organizations embrace "you build it, you run it"

- When "build" and "run" are owned by different teams, where's the line?

- What does the "build" team ship to the "run" team?

- Let's see a few options, and what they imply

---

## Shipping code

- Team "build" ships code

  (hopefully in a repository, identified by a commit hash)

- Team "run" containerizes that code

✔️ no extra work for developers

❌ very little advantage of using containers

---

## Shipping container images

- Team "build" ships container images

  (hopefully built automatically from a source repository)

- Team "run" uses theses images to create e.g. Kubernetes resources

✔️ universal artefact (support all languages uniformly)

✔️ easy to start a single component (good for monoliths)

❌ complex applications will require a lot of extra work

❌ adding/removing components in the stack also requires extra work

❌ complex applications will run very differently between dev and prod

---

## Shipping Compose files

(Or another kind of dev-centric manifest)

- Team "build" ships a manifest that works on a single node

  (as well as images, or ways to build them)

- Team "run" adapts that manifest to work on a cluster

✔️ all teams can start the stack in a reliable, deterministic manner

❌ adding/removing components still requires *some* work (but less than before)

❌ there will be *some* differences between dev and prod

---

## Shipping Kubernetes manifests

- Team "build" ships ready-to-run manifests

  (YAML, Helm charts, Kustomize ...)

- Team "run" adjusts some parameters and monitors the application

✔️ parity between dev and prod environments

✔️ "run" team can focus on SLAs, SLOs, and overall quality

❌ requires *a lot* of extra work (and new skills) from the "build" team

❌ Kubernetes is not a very convenient development platform (at least, not yet)

---

## What's the right answer?

- It depends on our teams

  - existing skills (do they know how to do it?)

  - availability (do they have the time to do it?)

  - potential skills (can they learn to do it?)

- It depends on our culture

  - owning "run" often implies being on call

  - do we reward on-call duty without encouraging hero syndrome?

  - do we give people resources (time, money) to learn?

---

class: extra-details

## Tools to develop on Kubernetes

*If we decide to make Kubernetes the primary development platform, here
are a few tools that can help us.*

- Docker Desktop

- Draft

- Minikube

- Skaffold

- Tilt

- ...

---

## Where do we run?

- Managed vs. self-hosted

- Cloud vs. on-premises

- If cloud: public vs. private

- Which vendor/distribution to pick?

- Which versions/features to enable?

---

## Developer experience

- How do we on-board a new developer?

- What do they need to install to get a dev stack?

- How does a code change make it from dev to prod?

- How does someone add a component to a stack?

*These questions are good "sanity checks" to validate our strategy!*

---

## Some guidelines

- Start small

- Outsource what we don't know

- Start simple, and stay simple as long as possible

  (try to stay away from complex features that we don't need)

- Automate

  (regularly check that we can successfully redeploy by following scripts)

- Transfer knowledge

  (make sure everyone is on the same page/level)

- Iterate!
