class: title

Let's get this party started!

---

class: pic

![Oprah's "you get a car" picture](images/you-get-a-cluster.jpg)

---

## Everyone gets their own cluster

- Everyone should have a little printed card

- That card has IP address / login / password for a personal cluster

- That cluster will be up for the duration of the tutorial

  (but not much longer, alas, because these cost $$$)

---

## How these clusters are deployed

- Create a bunch of cloud VMs

  (today: Ubuntu 18.04 on AWS EC2)

- Install binaries, create user account

  (with parallel-ssh because it's *fast*)

- Generate the little cards with a Jinja2 template

- If you want to do it for your own tutorial:

  check the [prepare-vms](https://github.com/jpetazzo/container.training/tree/master/prepare-vms) directory in the training repo!

---

## Exercises

- Labs and exercises are clearly identified

.exercise[

- This indicate something that you are invited to do

- First, let's log into the first node of the cluster:
  ```bash
  ssh docker@`A.B.C.D`
  ```

  (Replace A.B.C.D with the IP address of the first node)

]

---

## Slides

- These slides are available online

.exercise[

- Open this slides deck in a local browser:
  ```open
  @@SLIDES@@
  ```

- Select the tutorial link

- Type the number of that slide + ENTER

]
