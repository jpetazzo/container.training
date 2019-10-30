# Trainer tools to create and prepare VMs for Docker workshops

These tools can help you to create VMs on:

- Azure
- EC2
- OpenStack

## Prerequisites

- [Docker](https://docs.docker.com/engine/installation/)
- [Docker Compose](https://docs.docker.com/compose/install/)
- [Parallel SSH](https://code.google.com/archive/p/parallel-ssh/) (on a Mac: `brew install pssh`) 

Depending on the infrastructure that you want to use, you also need to install
the Azure CLI, the AWS CLI, or terraform (for OpenStack deployment).

And if you want to generate printable cards:

- [pyyaml](https://pypi.python.org/pypi/PyYAML)
- [jinja2](https://pypi.python.org/pypi/Jinja2)

You can install them with pip (perhaps with `pip install --user`, or even use `virtualenv` if that's your thing).

These require Python 3. If you are on a Mac, see below for specific instructions on setting up
Python 3 to be the default Python on a Mac. In particular, if you installed `mosh`, Homebrew
may have changed your default Python to Python 2.

## General Workflow

- fork/clone repo
- create an infrastructure configuration in the `prepare-vms/infra` directory
  (using one of the example files in that directory)
- create your own setting file from `settings/example.yaml`
- if necessary, increase allowed open files: `ulimit -Sn 10000`
- run `./workshopctl start` to create instances
- run `./workshopctl deploy` to install Docker and setup environment
- run `./workshopctl kube` (if you want to install and setup Kubernetes)
- run `./workshopctl cards` (if you want to generate PDF for printing handouts of each users host IP's and login info)
- run `./workshopctl stop` at the end of the workshop to terminate instances

## Clone/Fork the Repo, and Build the Tools Image

The Docker Compose file here is used to build a image with all the dependencies to run the `./workshopctl` commands and optional tools. Each run of the script will check if you have those dependencies locally on your host, and will only use the container if you're [missing a dependency](workshopctl#L5).

    $ git clone https://github.com/jpetazzo/container.training
    $ cd container.training/prepare-vms
    $ docker-compose build


## Preparing to Run `./workshopctl`

### Required AWS Permissions/Info

- Initial assumptions are you're using a root account. If you'd like to use a IAM user, it will need  `AmazonEC2FullAccess` and `IAMReadOnlyAccess`.
- Using a non-default VPC or Security Group isn't supported out of box yet, so you will have to customize `lib/commands.sh` if you want to change that.
- These instances will assign the default VPC Security Group, which does not open any ports from Internet by default. So you'll need to add Inbound rules for `SSH | TCP | 22 | 0.0.0.0/0` and `Custom TCP Rule | TCP | 8000 - 8002 | 0.0.0.0/0`, or run `./workshopctl opensg` which opens up all ports.

### Create your `infra` file

You need to do this only once. (On AWS, you can create one `infra`
file per region.)

Make a copy of one of the example files in the `infra` directory.

For instance:

```bash
cp infra/example.aws infra/aws-us-west-2
```

Edit your infrastructure file to customize it.
You will probably need to put your cloud provider credentials,
select region...

If you don't have the `aws` CLI installed, you will get a warning that it's a missing dependency. If you're not using AWS you can ignore this.

### Create your `settings` file

Similarly, pick one of the files in `settings` and copy it
to customize it.

For instance:

```bash
cp settings/example.yaml settings/myworkshop.yaml
```

You're all set!

## `./workshopctl` Usage

```
workshopctl - the orchestration workshop swiss army knife
Commands:
build                Build the Docker image to run this program in a container
cards                Generate ready-to-print cards for a group of VMs
deploy               Install Docker on a bunch of running VMs
disableaddrchecks    Disable source/destination IP address checks
disabledocker        Stop Docker Engine and don't restart it automatically
helmprom             Install Helm and Prometheus
help                 Show available commands
ids                  (FIXME) List the instance IDs belonging to a given tag or token
kubebins             Install Kubernetes and CNI binaries but don't start anything
kubereset            Wipe out Kubernetes configuration on all nodes
kube                 Setup kubernetes clusters with kubeadm (must be run AFTER deploy)
kubetest             Check that all nodes are reporting as Ready
listall              List VMs running on all configured infrastructures
list                 List available groups for a given infrastructure
netfix               Disable GRO and run a pinger job on the VMs
opensg               Open the default security group to ALL ingress traffic
ping                 Ping VMs in a given tag, to check that they have network access
pssh                 Run an arbitrary command on all nodes
pull_images          Pre-pull a bunch of Docker images
quotas               Check our infrastructure quotas (max instances)
remap_nodeports      Remap NodePort range to 10000-10999
retag                (FIXME) Apply a new tag to a group of VMs
ssh                  Open an SSH session to the first node of a tag
start                Start a group of VMs
stop                 Stop (terminate, shutdown, kill, remove, destroy...) instances
tags                 List groups of VMs known locally
test                 Run tests (pre-flight checks) on a group of VMs
weavetest            Check that weave seems properly setup
webssh               Install a WEB SSH server on the machines (port 1080)
wrap                 Run this program in a container
www                  Run a web server to access card HTML and PDF
```

### Summary of What `./workshopctl` Does For You

- Used to manage bulk AWS instances for you without needing to use AWS cli or gui.
- Can manage multiple "tags" or groups of instances, which are tracked in `prepare-vms/tags/`
- Can also create PDF/HTML for printing student info for instance IP's and login.
- The `./workshopctl` script can be executed directly.
- It will run locally if all its dependencies are fulfilled; otherwise it will run in the Docker container you created with `docker-compose build` (preparevms_prepare-vms).
- During `start` it will add your default local SSH key to all instances under the `ubuntu` user.
- During `deploy` it will create the `docker` user with password `training`, which is printing on the cards for students. This can be configured with the `docker_user_password` property in the settings file.

### Example Steps to Launch a group of AWS Instances for a Workshop

- Run `./workshopctl start --infra infra/aws-us-east-2 --settings/myworkshop.yaml --count 60` to create 60 EC2 instances
  - Your local SSH key will be synced to instances under `ubuntu` user
  - AWS instances will be created and tagged based on date, and IP's stored in `prepare-vms/tags/`
- Run `./workshopctl deploy TAG` to run `lib/postprep.py` via parallel-ssh
  - If it errors or times out, you should be able to rerun
  - Requires good connection to run all the parallel SSH connections, up to 100 parallel (ProTip: create dedicated management instance in same AWS region where you run all these utils from)
- Run `./workshopctl pull_images TAG` to pre-pull a bunch of Docker images to the instances
- Run `./workshopctl cards TAG` generates PDF/HTML files to print and cut and hand out to students
- *Have a great workshop*
- Run `./workshopctl stop TAG` to terminate instances.

### Example Steps to Launch Azure Instances

- Install the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) and authenticate with a valid account (`az login`)
- Customize `azuredeploy.parameters.json`
  - Required:
    - Provide the SSH public key you plan to use for instance configuration
  - Optional:
    - Choose a name for the workshop (default is "workshop")
    - Choose the number of instances (default is 3)
    - Customize the desired instance size (default is Standard_D1_v2)
 - Launch instances with your chosen resource group name and your preferred region; the examples are "workshop" and "eastus":
```
az group create --name workshop --location eastus
az group deployment create --resource-group workshop --template-file azuredeploy.json --parameters @azuredeploy.parameters.json
```

The `az group deployment create` command can take several minutes and will only say `- Running ..` until it completes, unless you increase the verbosity with `--verbose` or `--debug`.

To display the IPs of the instances you've launched:

```
az vm list-ip-addresses --resource-group workshop --output table
```

If you want to put the IPs into `prepare-vms/tags/<tag>/ips.txt` for a tag of "myworkshop":

1) If you haven't yet installed `jq` and/or created your event's tags directory in `prepare-vms`:

```
brew install jq
mkdir -p tags/myworkshop
```

2) And then generate the IP list:

```
az vm list-ip-addresses --resource-group workshop --output json | jq -r '.[].virtualMachine.network.publicIpAddresses[].ipAddress' > tags/myworkshop/ips.txt
```

After the workshop is over, remove the instances:

```
az group delete --resource-group workshop
```

### Example Steps to Configure Instances from a non-AWS Source

- Copy `infra/example.generic` to `infra/generic`
- Run `./workshopctl start --infra infra/generic --settings settings/...yaml`
- Note the `prepare-vms/tags/TAG/` path that has been auto-created.
- Launch instances via your preferred method. You'll need to get the instance IPs and be able to SSH into them.
- Edit the file `prepare-vms/tags/TAG/ips.txt`, it should list the IP addresses of the VMs (one per line, without any comments or other info)
- Continue deployment of cluster configuration with `./workshopctl deploy TAG`
- Optionally, configure Kubernetes clusters of the size in the settings: workshopctl kube `TAG`
- Optionally, test your Kubernetes clusters. They may take a little time to become ready: workshopctl kubetest `TAG`
- Generate cards to print and hand out: workshopctl cards `TAG`
- Print the cards file: prepare-vms/tags/`TAG`/ips.html


## Even More Details

#### Sync of SSH keys

When the `start` command is run, your local RSA SSH public key will be added to your AWS EC2 keychain.

To see which local key will be uploaded, run `ssh-add -l | grep RSA`.

#### Instance + tag creation

The VMs will be started, with an automatically generated tag (timestamp + your username).

Your SSH key will be added to the `authorized_keys` of the ubuntu user.

#### Creation of ./$TAG/ directory and contents

Following the creation of the VMs, a text file will be created containing a list of their IPs.

#### Deployment

Instances can be deployed manually using the `deploy` command:

    $ ./workshopctl deploy TAG

The `postprep.py` file will be copied via parallel-ssh to all of the VMs and executed.

#### Pre-pull images

    $ ./workshopctl pull_images TAG

#### Generate cards

    $ ./workshopctl cards TAG

If you want to generate both HTML and PDF cards, install [wkhtmltopdf](https://wkhtmltopdf.org/downloads.html); without that installed, only HTML cards will be generated.

If you don't have `wkhtmltopdf` installed, you will get a warning that it is a missing dependency. If you plan to just print the HTML cards, you can ignore this.

#### List tags

    $ ./workshopctl list infra/some-infra-file

    $ ./workshopctl listall

    $ ./workshopctl tags

#### Stop and destroy VMs

    $ ./workshopctl stop TAG

## ToDo

  - Don't write to bash history in system() in postprep
  - compose, etc version inconsistent (int vs str)

## Making sure Python3 is the default (Mac only)

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
