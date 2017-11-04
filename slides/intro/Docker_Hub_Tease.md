# Publishing images to the Docker Hub

We have built our first images.

If we were so inclined, we could share those images through the Docker Hub.

We won't do it since we don't want to force everyone to create a Docker Hub account (although it's free, yay!) but the steps would be:

* have an account on the Docker Hub

* tag our image accordingly (i.e. `username/imagename`)

* `docker push username/imagename`

Anybody can now `docker run username/imagename` from any Docker host.

Images can be set to be private as well.

---

## The goodness of automated builds

* You can link a Docker Hub repository with a GitHub or BitBucket repository

* Each push to GitHub or BitBucket will trigger a build on Docker Hub

* If the build succeeds, the new image is available on Docker Hub

* You can map tags and branches between source and container images

* If you work with public repositories, this is free

* Corollary: this gives you a very simple way to get free, basic CI

  (With the technique presented earlier)
