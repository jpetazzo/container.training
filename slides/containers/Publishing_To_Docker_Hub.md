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

.warning[When running Docker for Mac/Windows, or
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
* Go to the Docker Hub (https://hub.docker.com/) and sign-in. Select "Repositories" in the blue navigation menu.
* Select "Create" in the top-right bar, and select "Create Repository+".
* Connect your Docker Hub account to your GitHub account.
* Click "Create" button.
* Then go to "Builds" folder.
* Click on Github icon and select your user and the repository that we just forked.
* In "Build rules" block near page bottom, put `/www` in "Build Context" column (or whichever directory the Dockerfile is in).
* Click "Save and Build" to build the repository immediately (without waiting for a git push).
* Subsequent builds will happen automatically, thanks to GitHub hooks.

---

## Building on the fly

- Some services can build images on the fly from a repository

- Example: [ctr.run](https://ctr.run/)

.exercise[

- Use ctr.run to automatically build a container image and run it:
  ```bash
  docker run ctr.run/github.com/undefinedlabs/hello-world
  ```

]

There might be a long pause before the first layer is pulled,
because the API behind `docker pull` doesn't allow to stream build logs, and there is no feedback during the build.

It is possible to view the build logs by setting up an account on [ctr.run](https://ctr.run/).
