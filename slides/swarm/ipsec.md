# Securing overlay networks

- By default, overlay networks are using plain VXLAN encapsulation

  (~Ethernet over UDP, using SwarmKit's control plane for ARP resolution)

- Encryption can be enabled on a per-network basis

  (It will use IPSEC encryption provided by the kernel, leveraging hardware acceleration)

- This is only for the `overlay` driver

  (Other drivers/plugins will use different mechanisms)

---

## Creating two networks: encrypted and not

- Let's create two networks for testing purposes

.exercise[

- Create an "insecure" network:
  ```bash
  docker network create insecure --driver overlay --attachable
  ```

- Create a "secure" network:
  ```bash
  docker network create secure --opt encrypted --driver overlay --attachable
  ```

]

.warning[Make sure that you don't typo that option; errors are silently ignored!]

---

## Deploying a dual-homed web server

- Let's use good old NGINX

- We will attach it to both networks

- We will use a placement constraint to make sure that it is on a different node

.exercise[

- Create a web server running somewhere else:
  ```bash
    docker service create --name web \
           --network secure --network insecure \
           --constraint node.hostname!=node1 \
           nginx
  ```

]

---

## Sniff HTTP traffic

- We will use `ngrep`, which allows to grep for network traffic

- We will run it in a container, using host networking to access the host's interfaces

.exercise[

- Sniff network traffic and display all packets containing "HTTP":
  ```bash
  docker run --net host nicolaka/netshoot ngrep -tpd eth0 HTTP
  ```

<!-- ```wait User-Agent``` -->
<!-- ```key ^C``` -->

]

--

Seeing tons of HTTP request? Shutdown your DockerCoins workers:
```bash
docker service update dockercoins_worker --replicas=0
```

---

## Check that we are, indeed, sniffing traffic

- Let's see if we can intercept our traffic with Google!

.exercise[

- Open a new terminal

- Issue an HTTP request to Google (or anything you like):
  ```bash
  curl google.com
  ```

]

The ngrep container will display one `#` per packet traversing the network interface.

When you do the `curl`, you should see the HTTP request in clear text in the output.

---

class: extra-details

## If you are using Play-With-Docker, Vagrant, etc.

- You will probably have *two* network interfaces

- One interface will be used for outbound traffic (to Google)

- The other one will be used for internode traffic

- You might have to adapt/relaunch the `ngrep` command to specify the right one!

---

## Try to sniff traffic across overlay networks

- We will run `curl web` through both secure and insecure networks

.exercise[

- Access the web server through the insecure network:
  ```bash
  docker run --rm --net insecure nicolaka/netshoot curl web
  ```

- Now do the same through the secure network:
  ```bash
  docker run --rm --net secure nicolaka/netshoot curl web
  ```

]

When you run the first command, you will see HTTP fragments.
<br/>
However, when you run the second one, only `#` will show up.
