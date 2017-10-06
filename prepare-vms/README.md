# Trainer tools to create and prepare VMs for Docker workshops on AWS

## Prerequisites

- [Docker](https://docs.docker.com/engine/installation/)
- [Docker Compose](https://docs.docker.com/compose/install/)

## General Workflow

- fork/clone repo
- set required environment variables for AWS
- create your own setting file from `settings/example.yaml`
- run `./workshopctl` commands to create instances, install docker, setup each users environment in node1, other management tasks
- run `./workshopctl cards` command to generate PDF for printing handouts of each users host IP's and login info

## Clone/Fork the Repo, and Build the Tools Image

The Docker Compose file here is used to build a image with all the dependencies to run the `./workshopctl` commands and optional tools. Each run of the script will check if you have those dependencies locally on your host, and will only use the container if you're [missing a dependency](workshopctl#L5).

    $ git clone https://github.com/jpetazzo/orchestration-workshop.git
    $ cd orchestration-workshop/prepare-vms
    $ docker-compose build

## Preparing to Run `./workshopctl`

### Required AWS Permissions/Info

- Initial assumptions are you're using a root account. If you'd like to use a IAM user, it will need  `AmazonEC2FullAccess` and `IAMReadOnlyAccess`.
- Using a non-default VPC or Security Group isn't supported out of box yet, so you will have to customize `lib/commands.sh` if you want to change that.
- These instances will assign the default VPC Security Group, which does not open any ports from Internet by default. So you'll need to add Inbound rules for `SSH | TCP | 22 | 0.0.0.0/0` and `Custom TCP Rule | TCP | 8000 - 8002 | 0.0.0.0/0`, or run `./workshopctl opensg` which opens up all ports.

### Required Environment Variables

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_DEFAULT_REGION`

### Update/copy `settings/example.yaml`

Then pass `settings/YOUR_WORKSHOP_NAME-settings.yaml` as an argument to `./workshopctl deploy`, `./workshopctl cards`, etc.

./workshopctl cards 2016-09-28-00-33-bret settings/orchestration.yaml

## `./workshopctl` Usage

```
workshopctl - the orchestration workshop swiss army knife
Commands:
ami          Show the AMI that will be used for deployment
amis         List Ubuntu AMIs in the current region
cards        Generate ready-to-print cards for a batch of VMs
deploy       Install Docker on a bunch of running VMs
ec2quotas    Check our EC2 quotas (max instances)
help         Show available commands
ids          List the instance IDs belonging to a given tag or token
ips          List the IP addresses of the VMs for a given tag or token
kube         Setup kubernetes clusters with kubeadm (must be run AFTER deploy)
list         List available batches in the current region
opensg       Open the default security group to ALL ingress traffic
pull_images  Pre-pull a bunch of Docker images
retag        Apply a new tag to a batch of VMs
start        Start a batch of VMs
status       List instance status for a given batch
stop         Stop (terminate, shutdown, kill, remove, destroy...) instances
test         Run tests (pre-flight checks) on a batch of VMs
```

### Summary of What `./workshopctl` Does For You

- Used to manage bulk AWS instances for you without needing to use AWS cli or gui.
- Can manage multiple "tags" or groups of instances, which are tracked in `prepare-vms/tags/`
- Can also create PDF/HTML for printing student info for instance IP's and login.
- The `./workshopctl` script can be executed directly.
- It will run locally if all its dependencies are fulfilled; otherwise it will run in the Docker container you created with `docker-compose build` (preparevms_prepare-vms).
- During `start` it will add your default local SSH key to all instances under the `ubuntu` user.
- During `deploy` it will create the `docker` user with password `training`, which is printing on the cards for students. For now, this is hard coded.

### Example Steps to Launch a Batch of Instances for a Workshop

- Run `./workshopctl start N` Creates `N` EC2 instances
  - Your local SSH key will be synced to instances under `ubuntu` user
  - AWS instances will be created and tagged based on date, and IP's stored in `prepare-vms/tags/`
- Run `./workshopctl deploy TAG settings/somefile.yaml` to run `scripts/postprep.rc` via parallel-ssh
  - If it errors or times out, you should be able to rerun
  - Requires good connection to run all the parallel SSH connections, up to 100 parallel (ProTip: create dedicated management instance in same AWS region where you run all these utils from)
- Run `./workshopctl pull-images TAG` to pre-pull a bunch of Docker images to the instances
- Run `./workshopctl cards TAG settings/somefile.yaml` generates PDF/HTML files to print and cut and hand out to students
- *Have a great workshop*
- Run `./workshopctl stop TAG` to terminate instances.

## Other Tools

### Deploying your SSH key to all the machines

- Make sure that you have SSH keys loaded (`ssh-add -l`).
- Source `rc`.
- Run `pcopykey`.


### Installing extra packages

- Source `postprep.rc`.
  (This will install a few extra packages, add entries to
  /etc/hosts, generate SSH keys, and deploy them on all hosts.)


## Even More Details

#### Sync of SSH keys

When the `start` command is run, your local RSA SSH public key will be added to your AWS EC2 keychain.

To see which local key will be uploaded, run `ssh-add -l | grep RSA`.

#### Instance + tag creation

10 VMs will be started, with an automatically generated tag (timestamp + your username).

Your SSH key will be added to the `authorized_keys` of the ubuntu user.

#### Creation of ./$TAG/ directory and contents

Following the creation of the VMs, a text file will be created containing a list of their IPs.

This ips.txt file will be created in the $TAG/ directory and a symlink will be placed in the working directory of the script.

If you create new VMs, the symlinked file will be overwritten.

#### Deployment

Instances can be deployed manually using the `deploy` command:

    $ ./workshopctl deploy TAG settings/somefile.yaml

The `postprep.rc` file will be copied via parallel-ssh to all of the VMs and executed.

#### Pre-pull images

    $ ./workshopctl pull-images TAG

#### Generate cards

    $ ./workshopctl cards TAG settings/somefile.yaml

#### List tags

    $ ./workshopctl list

#### List VMs

    $ ./workshopctl list TAG

This will print a human-friendly list containing some information about each instance.

#### Stop and destroy VMs

    $ ./workshopctl stop TAG

## ToDo

  - Don't write to bash history in system() in postprep
  - compose, etc version inconsistent (int vs str)
