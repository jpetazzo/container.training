# Managing hosts with Docker Machine

- Docker Machine is a tool to provision and manage Docker hosts.

- It automates the creation of a virtual machine:

  - locally, with a tool like VirtualBox or VMware;

  - on a public cloud like AWS EC2, Azure, Digital Ocean, GCP, etc.;

  - on a private cloud like OpenStack.

- It can also configure existing machines through an SSH connection.

- It can manage as many hosts as you want, with as many "drivers" as you want.

---

## Docker Machine workflow

1) Prepare the environment: setup VirtualBox, obtain cloud credentials ...

2) Create hosts with `docker-machine create -d drivername machinename`.

3) Use a specific machine with `eval $(docker-machine env machinename)`.

4) Profit!

---

## Environment variables

- Most of the tools (CLI, libraries...) connecting to the Docker API can use environment variables.

- These variables are:

  - `DOCKER_HOST` (indicates address+port to connect to, or path of UNIX socket)

  - `DOCKER_TLS_VERIFY` (indicates that TLS mutual auth should be used)

  - `DOCKER_CERT_PATH` (path to the keypair and certificate to use for auth)

- `docker-machine env ...` will generate the variables needed to connect to a host.

- `$(eval docker-machine env ...)` sets these variables in the current shell.

---

## Host management features

With `docker-machine`, we can:

- upgrade a host to the latest version of the Docker Engine,

- start/stop/restart hosts,

- get a shell on a remote machine (with SSH),

- copy files to/from remotes machines (with SCP),

- mount a remote host's directory on the local machine (with SSHFS),

- ...

---

## The `generic` driver

When provisioning a new host, `docker-machine` executes these steps:

1) Create the host using a cloud or hypervisor API.

2) Connect to the host over SSH.

3) Install and configure Docker on the host.

With the `generic` driver, we provide the IP address of an existing host
(instead of e.g. cloud credentials) and we omit the first step.

This allows to provision physical machines, or VMs provided by a 3rd
party, or use a cloud for which we don't have a provisioning API.
