# Updating services

- We want to make changes to the web UI

- The process is as follows:

  - edit code

  - build new image

  - ship new image

  - run new image

---

## Updating a single service the hard way

- To update a single service, we could do the following:
  ```bash
  REGISTRY=localhost:5000 TAG=v0.3
  IMAGE=$REGISTRY/dockercoins_webui:$TAG
  docker build -t $IMAGE webui/
  docker push $IMAGE
  docker service update dockercoins_webui --image $IMAGE
  ```

- Make sure to tag properly your images: update the `TAG` at each iteration

  (When you check which images are running, you want these tags to be uniquely identifiable)

---

## Updating services the easy way

- With the Compose integration, all we have to do is:
  ```bash
  export TAG=v0.3
  docker-compose -f composefile.yml build
  docker-compose -f composefile.yml push
  docker stack deploy -c composefile.yml nameofstack
  ```

--

- That's exactly what we used earlier to deploy the app

- We don't need to learn new commands!

---

## Updating the web UI

- Let's make the numbers on the Y axis bigger!

.exercise[

- Edit the file `webui/files/index.html`:
  ```bash
  vi dockercoins/webui/files/index.html
  ```

  <!-- ```wait <title>``` -->

- Locate the `font-size` CSS attribute and increase it (at least double it)

  <!--
  ```keys /font-size```
  ```keys ^J```
  ```keys lllllllllllllcw45px```
  ```keys ^[``` ]
  ```keys :wq```
  ```keys ^J```
  -->

- Save and exit

- Build, ship, and run:
  ```bash
  export TAG=v0.3
  docker-compose -f dockercoins.yml build
  docker-compose -f dockercoins.yml push
  docker stack deploy -c dockercoins.yml dockercoins
  ```

]

---

## Viewing our changes

- Wait at least 10 seconds (for the new version to be deployed)

- Then reload the web UI

- Or just mash "reload" frantically

- ... Eventually the legend on the left will be bigger!
