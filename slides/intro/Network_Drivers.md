# Container network drivers

The Docker Engine supports many different network drivers.

The built-in drivers include:

* `bridge` (default)

* `none`

* `host`

* `container`

The driver is selected with `docker run --net ...`.

The different drivers are explained with more details on the following slides.

---

## The default bridge

* By default, the container gets a virtual `eth0` interface.
  <br/>(In addition to its own private `lo` loopback interface.)

* That interface is provided by a `veth` pair.

* It is connected to the Docker bridge.
  <br/>(Named `docker0` by default; configurable with `--bridge`.)

* Addresses are allocated on a private, internal subnet.
  <br/>(Docker uses 172.17.0.0/16 by default; configurable with `--bip`.)

* Outbound traffic goes through an iptables MASQUERADE rule.

* Inbound traffic goes through an iptables DNAT rule.

* The container can have its own routes, iptables rules, etc.

---

## The null driver

* Container is started with `docker run --net none ...`

* It only gets the `lo` loopback interface. No `eth0`.

* It can't send or receive network traffic.

* Useful for isolated/untrusted workloads.

---

## The host driver

* Container is started with `docker run --net host ...`

* It sees (and can access) the network interfaces of the host.

* It can bind any address, any port (for ill and for good).

* Network traffic doesn't have to go through NAT, bridge, or veth.

* Performance = native!

Use cases:

* Performance sensitive applications (VOIP, gaming, streaming...)

* Peer discovery (e.g. Erlang port mapper, Raft, Serf...)

---

## The container driver

* Container is started with `docker run --net container:id ...`

* It re-uses the network stack of another container.

* It shares with this other container the same interfaces, IP address(es), routes, iptables rules, etc.

* Those containers can communicate over their `lo` interface.
  <br/>(i.e. one can bind to 127.0.0.1 and the others can connect to it.)

