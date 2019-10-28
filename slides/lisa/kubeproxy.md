class: title

Pod-to-service networking

---

## What we will do

- Create a service to connect to our pods

  (with `kubectl expose deployment`)

- Try to connect to the service's ClusterIP

- If it works: victory

- Else: troubleshoot, try again

.footnote[*Note: the exact commands that I run will be available
in the slides of the tutorial.*]

---

class: pic

![Demo time!](images/demo-with-kht.png)

---

## What have we done?

- Started kube-proxy

- ... which created a bunch of iptables rules
