# Updating services

- We want to make changes to the web UI

- The process is as follows:

  - edit code

  - build new image

  - ship new image

  - run new image

---

## Updating a single service with `service update`

- To update a single service, we could do the following:
  ```bash
  export REGISTRY=127.0.0.1:5000
  export TAG=v0.2
  IMAGE=$REGISTRY/dockercoins_webui:$TAG
  docker build -t $IMAGE webui/
  docker push $IMAGE
  docker service update dockercoins_webui --image $IMAGE
  ```

- Make sure to tag properly your images: update the `TAG` at each iteration

  (When you check which images are running, you want these tags to be uniquely identifiable)

---

## Updating services with `stack deploy`

- With the Compose integration, all we have to do is:
  ```bash
  export TAG=v0.2
  docker-compose -f composefile.yml build
  docker-compose -f composefile.yml push
  docker stack deploy -c composefile.yml nameofstack
  ```

--

- That's exactly what we used earlier to deploy the app

- We don't need to learn new commands!

- It will diff each service and only update ones that changed

---

## Changing the code

- Let's make the numbers on the Y axis bigger!

.lab[

- Update the size of text on our webui:
  ```bash
  sed -i "s/15px/50px/" dockercoins/webui/files/index.html
  ```

]

---

## Build, ship, and run our changes

- Four steps:

  1. Set (and export!) the `TAG` environment variable
  2. `docker-compose build`
  3. `docker-compose push`
  4. `docker stack deploy`

.lab[

- Build, ship, and run:
  ```bash
  export TAG=v0.2
  docker-compose -f dockercoins.yml build
  docker-compose -f dockercoins.yml push
  docker stack deploy -c dockercoins.yml dockercoins
  ```

]

- Because we're tagging all images in this demo v0.2, deploy will update all apps, FYI

---

## Viewing our changes

- Wait at least 10 seconds (for the new version to be deployed)

- Then reload the web UI

- Or just mash "reload" frantically

- ... Eventually the legend on the left will be bigger!
