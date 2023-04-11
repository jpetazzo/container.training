# Tools to create lab environments

This directory contains tools to create lab environments for Docker and Kubernetes courses and workshops.

It also contains Terraform configurations that can be used stand-alone to create simple Kubernetes clusters.

Assuming that you have installed all the necessary dependencies, and placed cloud provider access tokens in the right locations, you could do, for instance:

```bash
# For a Docker course with 50 students,
# create 50 VMs on Digital Ocean.
./labctl create --students 50 --settings settings/docker.env --provider digitalocean

# For a Kubernetes training with 20 students,
# create 20 clusters of 4 VMs each using kubeadm,
# on a private Openstack cluster.
./labctl create --students 20 --settings settings/kubernetes.env --provider openstack/enix

# For a Kubernetes workshop with 80 students,
# create 80 clusters with 2 VMs each,
# using Scaleway Kapsule (managed Kubernetes).
./labctl create --students 20 --settings settings/mk8s.env --provider scaleway --mode mk8s
```

Interested? Read on!

## Software requirements

For Docker labs and Kubernetes labs based on kubeadm:

- [Parallel SSH](https://github.com/lilydjwg/pssh)
  (should be installable with `pip install git+https://github.com/lilydjwg/pssh`;
  on a Mac, try `brew install pssh`)

For all labs:

- Terraform

If you want to generate printable cards:

- [pyyaml](https://pypi.python.org/pypi/PyYAML)
- [jinja2](https://pypi.python.org/pypi/Jinja2)

These require Python 3. If you are on a Mac, see below for specific instructions on setting up
Python 3 to be the default Python on a Mac. In particular, if you installed `mosh`, Homebrew
may have changed your default Python to Python 2.

You will also need an account with the cloud provider(s) that you want to use to deploy the lab environments.

## Cloud provider account(s) and credentials

These scripts create VMs or Kubernetes cluster on cloud providers, so you will need cloud provider account(s) and credentials.

Generally, we try to use the credentials stored in the configuration file used by the cloud providers CLI tools.

This means, for instance, that for Linode, if you install `linode-cli` and configure it properly, it will place your credentials in `~/.config/linode-cli`, and our Terraform configurations will try to read that file and use the credentials in it.

You don't **have to** install the CLI tools of the cloud provider(s) that you want to use; but we recommend that you do.

If you want to provide your cloud credentials through other means, you will have to adjust the Terraform configuration files in `terraform/provider-config` accordingly.

## General Workflow

- fork/clone repo
- make sure your cloud credentials have been configured properly
- run `./labctl create ...` to create lab environments
- run `./labctl destroy ...` when you don't need the environments anymore

## Customizing things

You can edit the `settings/*.env` files, for instance to change the size of the clusters, the login or password used for the students...

Note that these files are sourced before executing any operation on a specific set of lab environments, which means that you can set Terraform variables by adding lines like the following one in the `*.env` files:

```bash
export TF_VAR_node_size=GP1.L
export TF_VAR_location=eu-north
```

## `./labctl` Usage

If you run `./labctl` without arguments, it will show a list of available commands.

### Summary of What `./labctl` Does For You

The script will create a Terraform configuration using a provider-specific template.

There are two modes: `pssh` and `mk8s`.

In `pssh` mode, students connect directly to the virtual machines using SSH.

The Terraform configuration creates a bunch of virtual machines, then the provisioning and configuration are done with `pssh`. There are a number of "steps" that are executed on the VMs, to install Docker, install a number of convenient tools, install and set up Kubernetes (if needed)... The list of "steps" to be executed is configured in the `settings/*.env` file.

In `mk8s` mode, students don't connect directly to the virtual machines. Instead, they connect to an SSH server running in a Pod (using the `jpetazzo/shpod` image), itself running on a Kubernetes cluster. The Kubernetes cluster is a managed cluster created by the Terraform configuration.

## `terraform` directory structure and principles

Legend:
- `📁` directory
- `📄` file
- `📄📄📄` multiple files
- `🌍` Terraform configuration that can be used "as-is"

```
📁terraform
├── 📁list-locations
│   └── 📄📄📄 helper scripts
│              (to list available locations for each provider)
├── 📁many-kubernetes
│   └── 📄📄📄 Terraform configuration template 
│              (used in mk8s mode)
├── 📁one-kubernetes
│   │ (contains Terraform configurations that can spawn
│   │  a single Kubernetes cluster on a given provider)
│   ├── 📁🌍aws
│   ├── 📁🌍civo
│   ├── 📄common.tf
│   ├── 📁🌍digitalocean
│   └── ...
├── 📁providers
│   ├── 📁aws
│   │   ├── 📄config.tf
│   │   └── 📄variables.tf
│   ├── 📁azure
│   │   ├── 📄config.tf
│   │   └── 📄variables.tf
│   ├── 📁civo
│   │   ├── 📄config.tf
│   │   └── 📄variables.tf
│   ├── 📁digitalocean
│   │   ├── 📄config.tf
│   │   └── 📄variables.tf
│   └── ...
├── 📁tags
│   │ (contains Terraform configurations + other files 
│   │  for a specific set of VMs or K8S clusters; these
│   │  are created by labctl)
│   ├── 📁2023-03-27-10-04-79-jp
│   ├── 📁2023-03-27-10-07-41-jp
│   ├── 📁2023-03-27-10-16-418-jp
│   └── ...
└── 📁virtual-machines
    │ (contains Terraform configurations that can spawn
    │  a bunch of virtual machines on a given provider)
    ├── 📁🌍aws
    ├── 📁🌍azure
    ├── 📄common.tf
    ├── 📁🌍digitalocean
    └── ...
```

The directory structure can feel a bit overwhelming at first, but it's built with specific goals in mind.

**Consistent input/output between providers.** The per-provider configurations in `one-kubernetes` all take the same input variables, and provide the same output variables. Same thing for the per-provider configurations in `virtual-machines`.

**Don't repeat yourself.** As much as possible, common variables, definitions, and logic has been factored in the `common.tf` file that you can see in `one-kubernetes` and `virtual-machines`. That file is then symlinked in each provider-specific directory, to make sure that all providers use the same version of the `common.tf` file.

**Don't repeat yourself (again).** The things that are specific to each provider have been placed in the `providers` directory, and are shared between the `one-kubernetes` and the `virtual-machines` configurations. Specifically, for each provider, there is `config.tf` (which contains provider configuration, e.g. how to obtain the credentials for that provider) and `variables.tf` (which contains default values like which location and which VM size to use).

**Terraform configurations should work in `labctl` or standalone, without extra work.** The Terraform configurations (identified by 🌍 in the directory tree above) can be used directly. Just go to one of these directories, `terraform init`, `terraform apply`, and you're good to go. But they can also be used from `labctl`. `labctl` shouldn't barf out if you did a `terraform apply` in one of these directories (because it will only copy the `*.tf` files, and leave alone the other files, like the Terraform state).

The latter means that it should be easy to tweak these configurations, or create a new one, without having to use `labctl` to test it. It also means that if you want to use these configurations but don't care about `labctl`, you absolutely can!

## Miscellaneous info

### Making sure Python3 is the default (Mac only)

Check the `/usr/local/bin/python` symlink. It should be pointing to
`/usr/local/Cellar/python/3`-something. If it isn't, follow these
instructions.

1) Verify that Python 3 is installed.

```
ls -la /usr/local/Cellar/Python
```

You should see one or more versions of Python 3. If you don't,
install it with `brew install python`.

2) Verify that `python` points to Python3.
 
```
ls -la /usr/local/bin/python
```

If this points to `/usr/local/Cellar/python@2`, then we'll need to change it.

```
rm /usr/local/bin/python
ln -s /usr/local/Cellar/Python/xxxx /usr/local/bin/python
# where xxxx is the most recent Python 3 version you saw above
```

### AWS specific notes

Initial assumptions are you're using a root account. If you'd like to use a IAM user, it will need the right permissions. For `pssh` mode, that includes at least `AmazonEC2FullAccess` and `IAMReadOnlyAccess`.

In `pssh` mode, the Terraform configuration currently uses the default VPC and Security Group. If you want to use another one, you'll have to make changes to `terraform/virtual-machines/aws`.

The default VPC Security Group does not open any ports from Internet by default. So you'll need to add Inbound rules for `SSH | TCP | 22 | 0.0.0.0/0` and `Custom TCP Rule | TCP | 8000 - 8002 | 0.0.0.0/0`.
