# Interconnecting clusters

- We assigned different Cluster CIDRs to each cluster

- This allows us to connect our clusters together

- We will leverage kube-router BGP abilities for that

- We will *peer* each kube-router instance with a *route reflector*

- As a result, we will be able to ping each other's pods

---

## Disclaimers

- There are many methods to interconnect clusters

- Depending on your network implementation, you will use different methods

- The method shown here only works for nodes with direct layer 2 connection

- We will often need to use tunnels or other network techniques

---

## The plan

- Someone will start the *route reflector*

  (typically, that will be the person presenting these slides!)

- We will update our kube-router configuration

- We will add a *peering* with the route reflector

  (instructing kube-router to connect to it and exchange route information)

- We should see the routes to other clusters on our nodes

  (in the output of e.g. `route -n` or `ip route show`)

- We should be able to ping pods of other nodes

---

## Starting the route reflector

- Only do this slide if you are doing this on your own

- There is a Compose file in the `compose/frr-route-reflector` directory

- Before continuing, make sure that you have the IP address of the route reflector

---

## Configuring kube-router

- This can be done in two ways:

  - with command-line flags to the `kube-router` process

  - with annotations to Node objects

- We will use the command-line flags

  (because it will automatically propagate to all nodes)

.footnote[Note: with Calico, this is achieved by creating a BGPPeer CRD.]

---

## Updating kube-router configuration

- We need to pass two command-line flags to the kube-router process

.exercise[

- Edit the `kuberouter.yaml` file

- Add the following flags to the kube-router arguments:
  ```
  - "--peer-router-ips=`X.X.X.X`"
  - "--peer-router-asns=64512"
  ```
  (Replace `X.X.X.X` with the route reflector address)

- Update the DaemonSet definition:
  ```bash
  kubectl apply -f kuberouter.yaml
  ```

]

---

## Restarting kube-router

- The DaemonSet will not update the pods automatically

  (it is using the default `updateStrategy`, which is `OnDelete`)

- We will therefore delete the pods

  (they will be recreated with the updated definition)

.exercise[

- Delete all the kube-router pods:
  ```bash
  kubectl delete pods -n kube-system -l k8s-app=kube-router
  ```

]

Note: the other `updateStrategy` for a DaemonSet is RollingUpdate.
<br/>
For critical services, we might want to precisely control the update process.

---

## Checking peering status

- We can see informative messages in the output of kube-router:
  ```
  time="2019-04-07T15:53:56Z" level=info msg="Peer Up"
  Key=X.X.X.X State=BGP_FSM_OPENCONFIRM Topic=Peer
  ```

- We should see the routes of the other clusters show up

- For debugging purposes, the reflector also exports a route to 1.0.0.2/32

- That route will show up like this:
  ```
  1.0.0.2     172.31.X.Y    255.255.255.255 UGH   0      0        0 eth0
  ```

- We should be able to ping the pods of other clusters!

---

## If we wanted to do more ...

- kube-router can also export ClusterIP addresses

  (by adding the flag `--advertise-cluster-ip`)

- They are exported individually (as /32)

- This would allow us to easily access other clusters' services

  (without having to resolve the individual addresses of pods)

- Even better if it's combined with DNS integration

  (to facilitate name → ClusterIP resolution)
