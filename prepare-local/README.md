DOCKER ORCHESTRATION (local environment instructions)
=====================================================

Instead of running this training on a cloud provider, you can simulate the
infrastructure locally. These instructions apply to the **PART ONE** of the
workshop.


## 1. Prerequisites

Virtualbox, Vagrant and Ansible

- Virtualbox: https://www.virtualbox.org/wiki/Downloads

- Vagrant: https://www.vagrantup.com/downloads.html

- Ansible:
  - install Ansible's prerequisites:

          $ sudo pip install paramiko PyYAML Jinja2 httplib2 six

  - clone the Ansible repository and checkout to a stable version
    (don't forget the `--recursive` argument when cloning!):

        $ git clone --recursive https://github.com/ansible/ansible.git
        $ cd ansible
        $ git checkout stable-2.0.0.1
        $ git submodule update

  - source the setup script to make Ansible available on this terminal session:

          $ source path/to/your-ansible-clone/hacking/env-setup

  - you need to repeat the last step everytime you open a new terminal session
    and want to use any Ansible command (but you'll probably only need to run
    it once).


## 2. Preparing the environment

Run the following commands:

    $ vagrant up
    $ ansible-playbook provisioning.yml

And that's it! Now you should be able to ssh on `node1` using:

    $ ssh vagrant@10.10.10.10 -i private-key

These are the default IP addresses for the nodes:

    10.10.10.10 node1
    10.10.10.20 node2
    10.10.10.30 node3
    10.10.10.40 node4
    10.10.10.50 node5

The source code of this repo will be mounted at `~/orchestration-workshop`
(only on the `node1`), so you can edit the code externally and the changes
will reflect inside the instance.


## 3. Possible problems and solutions

- Depending on the Vagrant version, `sudo apt-get install bsdtar` may be needed

- If you get strange Ansible errors about dependencies, try to check your pip
  version with `pip --version`. The current version is 8.1.1. If your pip is
  older than this, upgrade it with `sudo pip install --upgrade pip`, restart
  your terminal session and install the Ansible prerequisites again.

- If the IP's `10.10.10.[10-50]` are already taken in your machine, you can
  change them to other values in the `vagrant.yml` and `inventory` files in
  this directory. Make sure you pick a set of IP's inside the same subnet.

- If you suspend your computer, the simulated private network may stop to
  work. This is a known problem of Virtualbox. To fix it, reload all the VM's
  with `vagrant reload`.

- If you get a ssh error saying `WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED`
  it means that you already had in the past some other host using one of the
  IP addresses we use here. To solve this, remove the old entry in your
  `known_hosts` file with:

      $ ssh-keygen -f "~/.ssh/known_hosts" -R 10.10.10.10 -R 10.10.10.20 -R 10.10.10.30 -R 10.10.10.40 -R 10.10.10.50
