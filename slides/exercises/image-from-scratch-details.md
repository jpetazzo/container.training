# Exercise — Images from scratch

There are two parts in this exercise:

1. Obtaining and unpacking an image from scratch

2. Adding overlay mounts to the "container from scratch" lab

---

## Pulling from scratch, easy mode

- Download manifest and layers with `skopeo`

- Parse manifest and configuration with e.g. `jq`

- Uncompress the layers in a directory

- Check that the result works (using `chroot`)

---

## Pulling from scratch, medium mode

- Don't use `skopeo`

- Hints: if pulling from the Docker Hub, you'll need a token

  (there are examples in Docker's documentation)

---

## Pulling from scratch, hard mode

- Handle whiteouts!
