class: in-person

## Connecting to our lab environment

.exercise[

- Log into https://workshop.paulczar.wtf with your provided credentials

- Follow the instructions on the auth portal to set up a `kubeconfig` file.

- Check that you can connect to the cluster with `kubectl get nodes`:

```bash
$ kubectl get nodes
NAME                                      STATUS   ROLES    AGE   VERSION
vm-0f2b473c-5ae6-4af3-4e80-f0a068b03abe   Ready    <none>   23h   v1.14.5
vm-25cfc8d6-88c0-45f6-4305-05e859af7f2c   Ready    <none>   23h   v1.14.5
...
...
```
]

If anything goes wrong — ask for help!

---

## Doing or re-doing the workshop on your own?

- Use something like
  [Play-With-Docker](http://play-with-docker.com/) or
  [Play-With-Kubernetes](https://training.play-with-kubernetes.com/)

  Zero setup effort; but environment are short-lived and
  might have limited resources

- Create your own cluster (local or cloud VMs)

  Small setup effort; small cost; flexible environments

- Create a bunch of clusters for you and your friends
    ([instructions](https://@@GITREPO@@/tree/master/prepare-vms))

  Bigger setup effort; ideal for group training

---

class: self-paced

## Get your own Docker nodes

- If you already have some Docker nodes: great!

- If not: let's get some thanks to Play-With-Docker

.exercise[

- Go to http://www.play-with-docker.com/

- Log in

- Create your first node

<!-- ```open http://www.play-with-docker.com/``` -->

]

You will need a Docker ID to use Play-With-Docker.

(Creating a Docker ID is free.)

---

## Terminals

Once in a while, the instructions will say:
<br/>"Open a new terminal."

There are multiple ways to do this:

- create a new window or tab on your machine, and SSH into the VM;

- use screen or tmux on the VM and open a new window from there.

You are welcome to use the method that you feel the most comfortable with.
