# Trainer tools to prepare VMs for Docker workshops

There are several options for using these tools:

### Clone the repo

    $ git clone https://github.com/soulshake/prepare-vms.git
    $ cd prepare-vms
    $ docker-compose build
    $ mkdir $HOME/bin && ln -s `pwd`/trainer $HOME/bin/trainer

### Via the image

    $ docker pull soulshake/prepare-vms

### Submodule

This repo can be added as a submodule in the repo of the Docker workshop:

    $ git submodule add https://github.com/soulshake/prepare-vms.git

## Setup

### Export needed envvars

Required environment variables:

* `AWS_ACCESS_KEY_ID`
* `AWS_SECRET_ACCESS_KEY`
* `AWS_DEFAULT_REGION`



### Update settings.yaml

If you have more than one workshop:

    $ cp settings.yaml settings/YOUR_WORKSHOP_NAME-settings.yaml
    $ ln -s settings/YOUR_WORKSHOP_NAME-settings.yaml `pwd`/settings.yaml

Update the `settings.yaml` as needed. This is the file that will be used to generate cards.

## Usage

### Summary

Summary of steps to launch a batch of instances for a workshop:

* Export the environment variables needed by the AWS CLI (see **Requirements** below)
* `trainer start NUMBER_OF_VMS` to create AWS instances
* `trainer deploy TAG` to run `scripts/postprep.rc` via parallel-ssh
* `trainer pull-images TAG` to pre-pull a bunch of Docker images 
* `trainer test TAG`
* `trainer cards TAG` to generate a PDF and an HTML file you can print

The `trainer` script can be executed directly.

It will check for the necessary environment variables. Then, if all its dependencies are installed
locally, it will execute `trainer-cli`. If not, it will look for a local Docker image
tagged `soulshake/trainer-tools`. If found, it will run in a container. If not found,
the user will be prompted to either install the missing dependencies or download
the Docker image.

## Detailed usage

### Start some VMs

    $ trainer start 10

A few things will happen:

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

    $ trainer deploy TAG

The `postprep.rc` file will be copied via parallel-ssh to all of the VMs and executed.

### Pre-pull images

    $ trainer pull-images TAG

### Generate cards

    $ trainer cards TAG

### List tags

    $ trainer list

### List VMs

    $ trainer list TAG

This will print a human-friendly list containing some information about each instance.

### Stop and destroy VMs

    $ trainer stop TAG

## ToDo

  * Don't write to bash history in system() in postprep 
  * compose, etc version inconsistent (int vs str)
