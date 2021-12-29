## Brand new versions!

- Engine 18.09
- Compose 1.23
- Machine 0.16

.lab[

- Check all installed versions:
  ```bash
  docker version
  docker-compose -v
  docker-machine -v
  ```

]

---

## Wait, what, 18.09 ?!?

--

- Docker 1.13 = Docker 17.03 (year.month, like Ubuntu)

- Every month, there is a new "edge" release (with new features)

- Every quarter, there is a new "stable" release

- Docker CE releases are maintained 4+ months

- Docker EE releases are maintained 12+ months

- For more details, check the [Docker EE announcement blog post](https://blog.docker.com/2017/03/docker-enterprise-edition/)

---

class: extra-details

## Docker CE vs Docker EE

- Docker EE:

  - $$$
  - certification for select distros, clouds, and plugins
  - advanced management features (fine-grained access control, security scanning...)

- Docker CE:

  - free
  - available through Docker Mac, Docker Windows, and major Linux distros
  - perfect for individuals and small organizations

---

class: extra-details

## Why?

- More readable for enterprise users

  (i.e. the very nice folks who are kind enough to pay us big $$$ for our stuff)

- No impact for the community

  (beyond CE/EE suffix and version numbering change)

- Both trains leverage the same open source components

  (containerd, libcontainer, SwarmKit...)

- More predictable release schedule (see next slide)

---

class: pic

![Docker CE/EE release cycle](images/docker-ce-ee-lifecycle.png)

---

## What was added when?

||||
| ---- | ----- | --- |
| 2015 |  1.9  | Overlay (multi-host) networking, network/IPAM plugins
| 2016 |  1.10 | Embedded dynamic DNS
| 2016 |  1.11 | DNS round robin load balancing
| 2016 |  1.12 | Swarm mode, routing mesh, encrypted networking, healthchecks
| 2017 |  1.13 | Stacks, attachable overlays, image squash and compress
| 2017 |  1.13 | Windows Server 2016 Swarm mode
| 2017 | 17.03 | Secrets, encrypted Raft
| 2017 | 17.04 | Update rollback, placement preferences (soft constraints)
| 2017 | 17.06 | Swarm configs, node/service events, multi-stage build, service logs
| 2017 | 17.06 | Windows Server 2016 Swarm overlay networks, secrets
| 2017 | 17.09 | ADD/COPY chown, start\_period, stop-signal, overlay2 default
| 2017 | 17.12 | containerd, Hyper-V isolation, Windows routing mesh
| 2018 | 18.03 | Templates for secrets/configs, multi-yaml stacks, LCOW
| 2018 | 18.03 | Stack deploy to Kubernetes, `docker trust`, tmpfs, manifest CLI
