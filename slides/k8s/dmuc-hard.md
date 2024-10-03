# Adding nodes to the cluster

- In the previous section, we built a cluster with a single node

- In this new section, we're going to add more nodes to the cluster

- Note: we will need the lab environment of that previous section

- If you haven't done it yet, you should go through that section first

---

## Our environment

- On `polykube1`, we should have our Kubernetes control plane

- We're also assuming that we have the kubeconfig file created earlier

  (in `~/.kube/config`)

- We're going to work on `polykube2` and add it to the cluster

- This machine has exactly the same setup as `polykube1`

  (Ubuntu LTS with CNI, etcd, and Kubernetes binaries installed)

- Note that we won't need the etcd binaries here

  (the control plane will run solely on `polykube1`)

---

## Checklist

We need to:

- generate the kubeconfig file for `polykube2`

- install a container engine

- generate a CNI configuration file

- start kubelet

---

## Generating the kubeconfig file

- Ideally, we should generate a key pair and certificate for `polykube2`...

- ...and generate a kubeconfig file using these

- At the moment, for simplicity, we'll use the same key pair and certificate as earlier

- We have a couple of options:

  - copy the required files (kubeconfig, key pair, certificate)

  - "flatten" the kubeconfig file (embed the key and certificate within)

---

class: extra-details

## To flatten or not to flatten?

- "Flattening" the kubeconfig file can seem easier

  (because it means we'll only have one file to move around)

- But it's easier to rotate the key or renew the certificate when they're in separate files

---

## Flatten and copy the kubeconfig file

- We'll flatten the file and copy it over

.lab[

- On `polykube1`, flatten the kubeconfig file:
  ```bash
  kubectl config view --flatten > kubeconfig
  ```

- Then copy it to `polykube2`:
   ```bash
   scp kubeconfig polykube2:
   ```

]

---

## Generate CNI configuration

Back on `polykube2`, put the following in `/etc/cni/net.d/kube.conf`:

```json
{
  "cniVersion": "0.3.1",
  "name": "kube",
  "type": "bridge",
  "bridge": "cni0",
  "isDefaultGateway": true,
  "ipMasq": true,
  "hairpinMode": true,
  "ipam": {
    "type": "host-local",
    "subnet": `"10.1.2.0/24"`
  }
}
```

Note how we changed the subnet!

---

## Install container engine and start `kubelet`

.lab[

- Install `containerd`:
  ```bash
  sudo apt-get install containerd -y
  ```

- Start `containerd`:
  ```bash
  sudo systemctl start containerd
  ```

- Start `kubelet`:
  ```bash
  sudo kubelet --kubeconfig kubeconfig
  ```

]

We're getting errors looking like:
```
"Post \"https://localhost:6443/api/v1/nodes\": ... connect: connection refused"
```

---

## Updating the kubeconfig file

- Our kubeconfig file still references `localhost:6443`

- This was fine on `polykube1`

  (where `kubelet` was connecting to the control plane running locally)

- On `polykube2`, we need to change that and put the address of the API server

  (i.e. the address of `polykube1`)

.lab[

- Update the `kubeconfig` file:
  ```bash
  sed -i s/localhost:6443/polykube1:6443/ kubeconfig
  ```

]

---

## Starting `kubelet`

- `kubelet` should now start correctly (hopefully!)

.lab[

- On `polykube2`, start `kubelet`:
  ```bash
  sudo kubelet --kubeconfig kubeconfig
  ```

- On `polykube1`, check that `polykube2` shows up and is `Ready`:
  ```bash
  kubectl get nodes
  ```

]

---

## Testing connectivity

- From `polykube1`, can we connect to Pods running on `polykube2`? 🤔

.lab[

- Scale the test Deployment:
  ```bash
  kubectl scale deployment blue --replicas=5
  ```

- Get the IP addresses of the Pods:
  ```bash
  kubectl get pods -o wide
  ```

- Pick a Pod on `polykube2` and try to connect to it:
  ```bash
  curl `10.1.2.2`
  ```

]

--

At that point, it doesn't work.

---

## Refresher on the *pod network*

- The *pod network* (or *pod-to-pod network*) has a few responsibilities:

  - allocating and managing Pod IP addresses

  - connecting Pods and Nodes

  - connecting Pods together on a given node

  - *connecting Pods together across nodes*

- That last part is the one that's not functioning in our cluster

- It typically requires some combination of routing, tunneling, bridging...

---

## Connecting networks together

- We can add manual routes between our nodes

- This requires adding `N x (N-1)` routes

  (on each node, add a route to every other node)

- This will work on home labs where nodes are directly connected

  (e.g. on an Ethernet switch, or same WiFi network, or a bridge between local VMs)

- ...Or on clouds where IP address filtering has been disabled

  (by default, most cloud providers will discard packets going to unknown IP addresses)

- If IP address filtering is enabled, you'll have to use e.g. tunneling or overlay networks

---

## Important warning

- The technique that we are about to use doesn't work everywhere

- It only works if:

  - all the nodes are directly connected to each other (at layer 2)

  - the underlying network allows the IP addresses of our pods

- If we are on physical machines connected by a switch: OK

- If we are on virtual machines in a public cloud: NOT OK

  - on AWS, we need to disable "source and destination checks" on our instances

  - on OpenStack, we need to disable "port security" on our network ports

---

## Routing basics

- We need to tell *each* node:

  "The subnet 10.1.N.0/24 is located on node N" (for all values of N)

- This is how we add a route on Linux:
  ```bash
  ip route add 10.1.N.0/24 via W.X.Y.Z
  ```

  (where `W.X.Y.Z` is the internal IP address of node N)

- We can see the internal IP addresses of our nodes with:
  ```bash
  kubectl get nodes -o wide
  ```

---

## Adding our route

- Let's add a route from `polykube1` to `polykube2`

.lab[

- Check the internal address of `polykube2`:
  ```bash
  kubectl get node polykube2 -o wide
  ```

- Now, on `polykube1`, add the route to the Pods running on `polykube2`:
  ```bash
  sudo ip route add 10.1.2.0/24 via `A.B.C.D`
  ```

- Finally, check that we can now connect to a Pod running on `polykube2`:
  ```bash
  curl 10.1.2.2
  ```

]

---

## What's next?

- The network configuration feels very manual:

  - we had to generate the CNI configuration file (in `/etc/cni/net.d`)

  - we had to manually update the nodes' routing tables

- Can we automate that?

  **YES!**

- We could install something like [kube-router](https://www.kube-router.io/)

  (which specifically takes care of the CNI configuration file and populates routing tables)

- Or we could also go with e.g. [Cilium](https://cilium.io/)

---

class: extra-details

## If you want to try Cilium...

- Add the `--root-ca-file` flag to the controller manager:

  - use the certificate automatically generated by the API server
    <br/>
    (it should be in `/var/run/kubernetes/apiserver.crt`)

  - or generate a key pair and certificate for the API server and point to
  that certificate

  - without that, you'll get certificate validation errors
    <br/>
    (because in our Pods, the `ca.crt` file used to validate the API server will be empty)

- Check the Cilium [without kube-proxy][ciliumwithoutkubeproxy] instructions

  (make sure to pass the API server IP address and port!)

- Other pod-to-pod network implementations might also require additional steps

[ciliumwithoutkubeproxy]: https://docs.cilium.io/en/stable/network/kubernetes/kubeproxy-free/#kubeproxy-free

---

class: extra-details

## About the API server certificate...

- In the previous sections, we've skipped API server certificate verification

- To generate a proper certificate, we need to include a `subjectAltName` extension

- And make sure that the CA includes the extension in the certificate

```bash
openssl genrsa -out apiserver.key 4096

openssl req -new -key apiserver.key -subj /CN=kubernetes/ \
        -addext "subjectAltName = DNS:kubernetes.default.svc, \
        DNS:kubernetes.default, DNS:kubernetes, \
        DNS:localhost, DNS:polykube1" -out apiserver.csr

openssl x509 -req -in apiserver.csr -CAkey ca.key -CA ca.cert \
        -out apiserver.crt -copy_extensions copy
```

???

:EN:- Connecting nodes and pods
:FR:- Interconnecter les nœuds et les pods
