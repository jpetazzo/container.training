## How did we make our app "Swarm-ready"?

This app was written in June 2015. (One year before Swarm mode was released.)

What did we change to make it compatible with Swarm mode?

--

.lab[

- Go to the app directory:
  ```bash
  cd ~/container.training/dockercoins
  ```

- See modifications in the code:
  ```bash
  git log -p --since "4-JUL-2015" -- . ':!*.yml*' ':!*.html'
  ```

  <!-- ```wait commit``` -->
  <!-- ```keys q``` -->

]

---

## Which files have been changed since then?

- Compose files

- HTML file (it contains an embedded contextual tweet)

- Dockerfiles (to switch to smaller images)

- That's it!

--

*We didn't change a single line of code in this app since it was written.*

--

*The images that were [built in June 2015](
https://hub.docker.com/r/jpetazzo/dockercoins_worker/tags/)
(when the app was written) can still run today ...
<br/>... in Swarm mode (distributed across a cluster, with load balancing) ...
<br/>... without any modification.*

---

## How did we design our app in the first place?

- [Twelve-Factor App](https://12factor.net/) principles

- Service discovery using DNS names

  - Initially implemented as "links"

  - Then "ambassadors"

  - And now "services"

- Existing apps might require more changes!
