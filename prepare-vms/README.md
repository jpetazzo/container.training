# Trainer tools to prepare VMs for Docker workshops

## 1. Prerequisites

* [Docker](https://docs.docker.com/engine/installation/)
* [Docker Compose](https://docs.docker.com/compose/install/)

## 2. Clone the repo

    $ git clone https://github.com/jpetazzo/orchestration-workshop.git
    $ cd orchestration-workshop/prepare-vms
    $ docker-compose build
    $ ./trainer <commands>  # See "Summary of commands" section below

## 3. Preparing the environment

Required environment variables:

* `AWS_ACCESS_KEY_ID`
* `AWS_SECRET_ACCESS_KEY`
* `AWS_DEFAULT_REGION`

### 4. Update settings.yaml

If you have more than one workshop:

    $ cp settings/default.yaml settings/YOUR_WORKSHOP_NAME-settings.yaml

Then pass `settings/YOUR_WORKSHOP_NAME-settings.yaml` as an argument to `deploy`, `cards`, etc.

## Usage

### Summary of commands

The `trainer` script can be executed directly.

Summary of steps to launch a batch of instances for a workshop:

* Export the environment variables needed by the AWS CLI (see **2. Preparing the environment** above)
* `./trainer start N` (where `N` is the number of AWS instances to create)
* `./trainer list` to view the list of tags
* `./trainer list TAG` to view the instances with a given `TAG`
* `./trainer deploy TAG settings/somefile.yaml` to run `scripts/postprep.rc` via parallel-ssh
* `./trainer pull-images TAG` to pre-pull a bunch of Docker images to the instances
* `./trainer test TAG`
* `./trainer cards TAG settings/somefile.yaml` to generate a PDF and an HTML file you can print and cut to hand out cards with connection information to attendees

`./trainer` will run locally if all its dependencies are fulfilled; otherwise it will run in a Docker container.

It will check for the necessary environment variables. Then, if all its dependencies are installed
locally, it will execute `trainer-cli`. If not, it will look for a local Docker image
tagged `preparevms_prepare-vms` (created automatically when you run `docker-compose build`).
If found, it will run in a container. If not found, the user will be prompted to
either install the missing dependencies or run `docker-compose build`.

## Detailed usage

### Start some VMs

    $ ./trainer start 10

A few things will happen:

* Your local SSH key will be synced
* AWS instances will be created and tagged
* A directory will be created

Details below.

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

## Deployment

Instances can be deployed manually using the `deploy` command:

    $ ./trainer deploy TAG settings/somefile.yaml

The `postprep.rc` file will be copied via parallel-ssh to all of the VMs and executed.

### Pre-pull images

    $ ./trainer pull-images TAG

### Generate cards

    $ ./trainer cards TAG settings/somefile.yaml

### List tags

    $ ./trainer list

### List VMs

    $ ./trainer list TAG

This will print a human-friendly list containing some information about each instance.

### Stop and destroy VMs

    $ ./trainer stop TAG

## ToDo

  * Don't write to bash history in system() in postprep 
  * compose, etc version inconsistent (int vs str)
