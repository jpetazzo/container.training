# Init systems and PID 1

In this chapter, we will consider:

- the role of PID 1 in the world of Docker,

- how to avoid some common pitfalls due to the misuse of init systems.

---

## What's an init system?

- On UNIX, the "init system" (or "init" in short) is PID 1.

- It is the first process started by the kernel when the system starts.

- It has multiple responsibilities:

  - start every other process on the machine,

  - reap orphaned zombie processes.

---

class: extra-details

## Orphaned zombie processes ?!?

- When a process exits (or "dies"), it becomes a "zombie".

  (Zombie processes show up in `ps` or `top` with the status code `Z`.)

- Its parent process must *reap* the zombie process.

  (This is done by calling `waitpid()` to retrieve the process' exit status.)

- When a process exits, if it has child processes, these processes are "orphaned."

- They are then re-parented to PID 1, init.

- Init therefore needs to take care of these orphaned processes when they exit.

---

## Don't use init systems in containers

- It's often tempting to use an init system or a process manager.

  (Examples: *systemd*, *supervisord*...)

- Our containers are then called "system containers".

  (By contrast with "application containers".)

- "System containers" are similar to lightweight virtual machines.

- They have multiple downsides:

  - when starting multiple processes, their logs get mixed on stdout,

  - if the application process dies, the container engine doesn't see it.

- Overall, they make it harder to operate troubleshoot containerized apps.

---

## Exceptions and workarounds

- Sometimes, it's convenient to run a real init system like *systemd*.

  (Example: a CI system whose goal is precisely to test an init script or unit file.)

- If we need to run multiple processes: can we use multiple containers?

  (Example: [this Compose file](https://github.com/jpetazzo/container.training/blob/master/compose/simple-k8s-control-plane/docker-compose.yaml) runs multiple processes together.)

- When deploying with Kubernetes:

  - a container belong to a pod,

  - a pod can have multiple containers.

---

## What about these zombie processes?

- Our application runs as PID 1 in the container.

- Our application may or may not be designed to reap zombie processes.

- If our application uses subprocesses and doesn't reap them ...

  ... this can lead to PID exhaustion!

  (Or, more realistically, to a confusing herd of zombie processes.)

- How can we solve this?

---

## Tini to the rescue

- Docker can automatically provide a minimal `init` process.

- This is enabled with `docker run --init ...`

- It uses a small init system ([tini](https://github.com/krallin/tini)) as PID 1:

  - it reaps zombies,

  - it forwards signals,

  - it exits when the child exits.

- It is totally transparent to our application.

- We should use it if our application creates subprocess but doesn't reap them.

---

class: extra-details

## What about Kubernetes?

- Kubernetes does not expose that `--init` option.

- However, we can achieve the same result with [Process Namespace Sharing](https://kubernetes.io/docs/tasks/configure-pod-container/share-process-namespace/).

- When Process Namespace Sharing is enabled, PID 1 will be `pause`.

- That `pause` process takes care of reaping zombies.

- Process Namespace Sharing is available since Kubernetes 1.16.

- If you're using an older version of Kubernetes ...

  ... you might have to add `tini` explicitly to your Docker image.
