class: in-person

## Connecting to our lab environment

.lab[

- Log into the first VM (`node1`) with your SSH client:
  ```bash
  ssh `user`@`A.B.C.D`
  ```

  (Replace `user` and `A.B.C.D` with the user and IP address provided to you)

<!--
```bash
for N in $(awk '/\Wnode/{print $2}' /etc/hosts); do
  ssh -o StrictHostKeyChecking=no $N true
done
```

```bash
### FIXME find a way to reset the cluster, maybe?
```
-->

]

You should see a prompt looking like this:
```
[A.B.C.D] (...) user@node1 ~
$
```
If anything goes wrong — ask for help!

---

class: in-person

## `tailhist`

- The shell history of the instructor is available online in real time

- Note the IP address of the instructor's virtual machine (A.B.C.D)

- Open http://A.B.C.D:1088 in your browser and you should see the history

- The history is updated in real time

  (using a WebSocket connection)

- It should be green when the WebSocket is connected

  (if it turns red, reloading the page should fix it)

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

## For a consistent Kubernetes experience ...

- If you are using your own Kubernetes cluster, you can use [jpetazzo/shpod](https://github.com/jpetazzo/shpod)

- `shpod` provides a shell running in a pod on your own cluster

- It comes with many tools pre-installed (helm, stern...)

- These tools are used in many demos and exercises in these slides

- `shpod` also gives you completion and a fancy prompt

- It can also be used as an SSH server if needed

---

class: self-paced

## Get your own Docker nodes

- If you already have some Docker nodes: great!

- If not: let's get some thanks to Play-With-Docker

.lab[

- Go to http://www.play-with-docker.com/

- Log in

- Create your first node

<!-- ```open http://www.play-with-docker.com/``` -->

]

You will need a Docker ID to use Play-With-Docker.

(Creating a Docker ID is free.)

---

## We will (mostly) interact with node1 only

*These remarks apply only when using multiple nodes, of course.*

- Unless instructed, **all commands must be run from the first VM, `node1`**

- We will only check out/copy the code on `node1`

- During normal operations, we do not need access to the other nodes

- If we had to troubleshoot issues, we would use a combination of:

  - SSH (to access system logs, daemon status...)

  - Docker API (to check running containers and container engine status)

---

## Terminals

Once in a while, the instructions will say:
<br/>"Open a new terminal."

There are multiple ways to do this:

- create a new window or tab on your machine, and SSH into the VM;

- use screen or tmux on the VM and open a new window from there.

You are welcome to use the method that you feel the most comfortable with.

---

## Tmux cheat sheet

[Tmux](https://en.wikipedia.org/wiki/Tmux) is a terminal multiplexer like `screen`.

*You don't have to use it or even know about it to follow along.
<br/>
But some of us like to use it to switch between terminals.
<br/>
It has been preinstalled on your workshop nodes.*

- Ctrl-b c → creates a new window
- Ctrl-b n → go to next window
- Ctrl-b p → go to previous window
- Ctrl-b " → split window top/bottom
- Ctrl-b % → split window left/right
- Ctrl-b Alt-1 → rearrange windows in columns
- Ctrl-b Alt-2 → rearrange windows in rows
- Ctrl-b arrows → navigate to other windows
- Ctrl-b d → detach session
- tmux attach → re-attach to session
