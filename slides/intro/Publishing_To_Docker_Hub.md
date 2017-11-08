# Publishing images to the Docker Hub

We have built our first images.

We can now publish it to the Docker Hub!

*You don't have to do the exercises in this section,
because they require an account on the Docker Hub, and we
don't want to force anyone to create one.*

*Note, however, that creating an account on the Docker Hub
is free (and doesn't require a credit card), and hosting
public images is free as well.*

---

## Logging into our Docker Hub account

* This can be done from the Docker CLI:
  ```bash
  docker login
  ```

.warning[When running Docker4Mac, Docker4Windows, or
Docker on a Linux workstation, it can (and will when
possible) integrate with your system's keyring to
store your credentials securely. However, on most Linux
servers, it will store your credentials in `~/.docker/config`.]

---

## Image tags and registry addresses

* Docker images tags are like Git tags and branches.

* They are like *bookmarks* pointing at a specific image ID.

* Tagging an image doesn't *rename* an image: it adds another tag.

* When pushing an image to a registry, the registry address is in the tag.

  Example: `registry.example.net:5000/image`

* What about Docker Hub images?

--

* `jpetazzo/clock` is, in fact, `index.docker.io/jpetazzo/clock`

* `ubuntu` is, in fact, `library/ubuntu`, i.e. `index.docker.io/library/ubuntu`

---

## Tagging an image to push it on the Hub

* Let's tag our `figlet` image (or any other to our liking):
  ```bash
  docker tag figlet jpetazzo/figlet
  ```

* And push it to the Hub:
  ```bash
  docker push jpetazzo/figlet
  ```

* That's it!

--

* Anybody can now `docker run jpetazzo/figlet` anywhere.

---

## The goodness of automated builds

* You can link a Docker Hub repository with a GitHub or BitBucket repository

* Each push to GitHub or BitBucket will trigger a build on Docker Hub

* If the build succeeds, the new image is available on Docker Hub

* You can map tags and branches between source and container images

* If you work with public repositories, this is free

---

class: extra-details

## Setting up an automated build

* We need a Dockerized repository!
* Let's go to https://github.com/jpetazzo/trainingwheels and fork it.
* Go to the Docker Hub (https://hub.docker.com/).
* Select "Create" in the top-right bar, and select "Create Automated Build."
* Connect your Docker Hub account to your GitHub account.
* Select your user and the repository that we just forked.
* Create.
* Then go to "Build Settings."
* Put `/www` in "Dockerfile Location" (or whichever directory the Dockerfile is in).
* Click "Trigger" to build the repository immediately (without waiting for a git push).
* Subsequent builds will happen automatically, thanks to GitHub hooks.
