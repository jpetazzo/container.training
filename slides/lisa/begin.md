class: title

@@TITLE@@

.footnote[![QR Code to the slides](images/qrcode-lisa.png)☝🏻 Slides!]

---

## Outline

- Introductions

- Kubernetes anatomy

- Building a 1-node cluster

- Connecting to services

- Adding more nodes

- What's missing

---

class: title

Introductions

---

class: tutorial-only

## Viewer advisory

- Have you attended my talk on Monday?

--

- Then you may experience *déjà-vu* during the next few minutes

  (Sorry!)

--

- But I promise we'll soon build (and break) some clusters!

---

## Hi!

- Jérôme Petazzoni ([@jpetazzo](https://twitter.com/jpetazzo))

- 🇫🇷🇺🇸🇩🇪

- 📦🧔🏻

- 🐋(📅📅📅📅📅📅📅)

- 🔥🧠😢💊 ([1], [2], [3])

- 👨🏻‍🏫✨☸️💰

- 😄👍🏻

[1]: http://jpetazzo.github.io/2018/09/06/the-depression-gnomes/
[2]: http://jpetazzo.github.io/2018/02/17/seven-years-at-docker/
[3]: http://jpetazzo.github.io/2017/12/24/productivity-depression-kanban-emoji/

???

I'm French, living in the US, with also a foot in Berlin (Germany).

I'm a container hipster: I was running containers in production,
before it was cool.

I worked 7 years at Docker, which according to Corey Quinn,
is "long enough to be legally declared dead".

I also struggled a few years with depressed and burn-out.
It's not what I'll discuss today, but it's a topic that matters
a lot to me, and I wrote a bit about it, check my blog if you'd like.

After a break, I decided to do something I love:
teaching witchcraft. I deliver Kubernetes training.

As you can see, I love emojis, but if you don't, it's OK.
(There will be much less emojis on the following slides.)

---

## Why this talk?

- One of my goals in 2018: pass the CKA exam

--

- Things I knew:

  - kubeadm

  - kubectl run, expose, YAML, Helm

  - ancient container lore

--

- Things I didn't:

  - how Kubernetes *really* works

  - deploy Kubernetes The Hard Way

---

## Scope

- Goals:

  - learn enough about Kubernetes to ace that exam

  - learn enough to teach that stuff

- Non-goals:

  - set up a *production* cluster from scratch

  - build everything from source

---

## Why are *you* here?

--

- Need/want/must build Kubernetes clusters

--

- Just curious about Kubernetes internals

--

- The Zelda theme

--

- (Other, please specify)

--

class: tutorial-only

.footnote[*Damn. Jérôme is even using the same jokes for his talk and his tutorial!<br/>This guy really has no shame. Tsk.*]

---

class: title

TL,DR

---

class: title

*The easiest way to install Kubernetes
is to get someone else to do it for you.*

(Me, after extensive research.)

???

Which means that if any point, you decide to leave,
I will not take it personally, but assume that you
eventually saw the light, and that you would like to
hire me or some of my colleagues to build your
Kubernetes clusters. It's all good.

---

class: talk-only

## This talk is also available as a tutorial

- Wednesday, October 30, 2019 - 11:00 am–12:30 pm

- Salon ABCD

- Same content

- Everyone will get a cluster of VMs

- Everyone will be able to do the stuff that I'll demo today!

---

class: title

The Truth¹ About Kubernetes

.footnote[¹Some of it]

---

## What we want to do

```bash
kubectl run web --image=nginx --replicas=3
```

*or*

```bash
kubectl create deployment web --image=nginx
kubectl scale deployment web --replicas=3
```

*then*

```bash
kubectl expose deployment web --port=80
curl http://...
```

???

Kubernetes might feel like an imperative system,
because we can say "run this; do that."

---

## What really happens

- `kubectl` generates a manifest describing a Deployment

- That manifest is sent to the Kubernetes API server

- The Kubernetes API server validates the manifest

- ... then persists it to etcd

- Some *controllers* wake up and do a bunch of stuff

.footnote[*The amazing diagram on the next slide is courtesy of [Lucas Käldström](https://twitter.com/kubernetesonarm).*]

???

In reality, it is a declarative system.

We write manifests, descriptions of what we want, and Kubernetes tries to make it happen.

---

class: pic

![Diagram showing Kubernetes architecture](images/k8s-arch4-thanks-luxas.png)

???

What we're really doing, is storing a bunch of objects in etcd.
But etcd, unlike a SQL database, doesn't have schemas or types.
So to prevent us from dumping any kind of trash data in etcd,
We have to read/write to it through the API server.
The API server will enforce typing and consistency.

Etcd doesn't have schemas or types, but it has the ability to
watch a key or set of keys, meaning that it's possible to subscribe
to updates of objects.
The controller manager is a process that has a bunch of loops,
each one responsible for a specific type of object.
So there is one that will watch the deployments, and as soon
as we create, updated, delete a deployment, it will wake up
and do something about it.
