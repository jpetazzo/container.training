# Init-systems and PID 1

In this chapter, we will consider the role of PID 1 in the world of Docker,

and how to avoid some common pitfalls due to the misuse of init-systems.

---
## Don't use init-systems

- It's often tempting to use init-systems (*systemd*, *supervisord*)

  and use docker as a "lightweight VM"

- This often a bad idea, as it make things harder to debug:

  - *example 1*: if you start a container changing it's entrypoint to a shell,

      how to easily start the original process ?

  - *example 2*: if you run multiple process, logs are mixed to stdout

  - *example 3*: you're process is dying but you're init process is not

      => the container is running for nothing

---
## Don't use init-systems, but ...

- In UNIX, a dead child process still use a PID till it's parent read it's status

- In the meantime of being read by it's parent,

  those process are called `Zombie` or `defunct` process

- If not being ripped off, zombie processes could crash a server (PID exhaution)

- If the parent also dies before reading it's child container the zombie are attach to the PID 1 in some cases.

- On a VM or real system, one of the role of the PID 1(Init-systems) is to rip zombies.

  *This also apply to containers*

---
## Use an init

- You're application is running as PID 1 in the docker container

- You're application is surely not designed to read status of random attaching child

- Then everything is blowing up due to PID exhaution

  => Docker now has a built-in init you can enable `docker run --init`

- This is a small init-system([tini](https://github.com/krallin/tini)) that takes the role of PID 1

- Only rips zombies, completly transparent otherwise

  (forwards signals, exit when child exit, etc).

- Orchestrators like kubernetes has no option to turn `--init` when running container,

  so you might want to add explicitly to you're docker image, and use it as entrypoint

---
## Use it or not ?

- Sometimes it's also handy to run a full init-system like *systemd*:

  - In CI when you're goal is exactly to test an init-script or a unit-file.

- You might think, if it's ok for *systemd*, this is surely ok for *supervisord*

  especially running multiple times the same process (then, mixed logs is not a big deal)

  => I would strongly *NOT* recommand to do so.

- It's often design to restart unhealthy process automatically

  and thus masquerade things to the operator or to the orchestrator (whose role is identical)
