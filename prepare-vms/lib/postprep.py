#!/usr/bin/env python
import os
import platform
import sys
import time
import urllib
import yaml

#################################

config = yaml.load(open("/tmp/settings.yaml"))
COMPOSE_VERSION = config["compose_version"]
MACHINE_VERSION = config["machine_version"]
CLUSTER_SIZE = config["clustersize"]
ENGINE_VERSION = config["engine_version"]

#################################

# This script will be run as ubuntu user, which has root privileges.
# docker commands will require sudo because the ubuntu user has no access to the docker socket.

STEP = 0
START = time.time()

def bold(msg):
    return "{} {} {}".format("$(tput smso)", msg, "$(tput rmso)")

def system(cmd):
    global STEP
    with open("/tmp/pp.status", "a") as f:
        t1 = time.time()
        f.write(bold("--- RUNNING [step {}] ---> {}...".format(STEP, cmd)))
        retcode = os.system(cmd)
        t2 = time.time()
        td = str(t2-t1)[:5]
        f.write(bold("[{}] in {}s\n".format(retcode, td)))
        STEP += 1
    with open("/home/ubuntu/.bash_history", "a") as f:
        f.write("{}\n".format(cmd))
    if retcode != 0:
        msg = "The following command failed with exit code {}:\n".format(retcode)
        msg+= cmd
        raise(Exception(msg))


# On EC2, the ephemeral disk might be mounted on /mnt.
# If /mnt is a mountpoint, place Docker workspace on it.
system("if mountpoint -q /mnt; then sudo mkdir /mnt/docker && sudo ln -s /mnt/docker /var/lib/docker; fi")

# Put our public IP in /tmp/ipv4
# ipv4_retrieval_endpoint = "http://169.254.169.254/latest/meta-data/public-ipv4"
ipv4_retrieval_endpoint = "http://myip.enix.org/REMOTE_ADDR"
system("curl --silent {} > /tmp/ipv4".format(ipv4_retrieval_endpoint))

ipv4 = open("/tmp/ipv4").read()

# Add a "docker" user with password "training"
system("id docker || sudo useradd -d /home/docker -m -s /bin/bash docker")
system("echo docker:training | sudo chpasswd")

# Fancy prompt courtesy of @soulshake.
system("""sudo -u docker tee -a /home/docker/.bashrc <<SQRL
export PS1='\e[1m\e[31m[{}] \e[32m(\\$(docker-prompt)) \e[34m\u@\h\e[35m \w\e[0m\n$ '
SQRL""".format(ipv4))

# Custom .vimrc
system("""sudo -u docker tee /home/docker/.vimrc <<SQRL
syntax on
set autoindent
set expandtab
set number
set shiftwidth=2
set softtabstop=2
SQRL""")

# add docker user to sudoers and allow password authentication
system("""sudo tee /etc/sudoers.d/docker <<SQRL
docker ALL=(ALL) NOPASSWD:ALL
SQRL""")

system("sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config")

system("sudo service ssh restart")
system("sudo apt-get -q update")
system("sudo apt-get -qy install git jq python-pip")

#######################
### DOCKER INSTALLS ###
#######################

# This will install the latest Docker.
#system("curl --silent https://{}/ | grep -v '( set -x; sleep 20 )' | sudo sh".format(ENGINE_VERSION))
system("sudo apt-get -qy install apt-transport-https ca-certificates curl software-properties-common")
system("curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -")
system("sudo add-apt-repository 'deb [arch=amd64] https://download.docker.com/linux/ubuntu xenial {}'".format(ENGINE_VERSION))
system("sudo apt-get -q update")
system("sudo apt-get -qy install docker-ce")

### Install docker-compose
#system("sudo pip install -U docker-compose=={}".format(COMPOSE_VERSION))
system("sudo curl -sSL -o /usr/local/bin/docker-compose https://github.com/docker/compose/releases/download/{}/docker-compose-{}-{}".format(COMPOSE_VERSION, platform.system(), platform.machine()))
system("sudo chmod +x /usr/local/bin/docker-compose")
system("docker-compose version")

### Install docker-machine
system("sudo curl -sSL -o /usr/local/bin/docker-machine https://github.com/docker/machine/releases/download/v{}/docker-machine-{}-{}".format(MACHINE_VERSION, platform.system(), platform.machine()))
system("sudo chmod +x /usr/local/bin/docker-machine")
system("docker-machine version")

system("sudo apt-get remove -y --purge dnsmasq-base")
system("sudo apt-get -qy install python-setuptools pssh apache2-utils httping htop unzip mosh")

### Wait for Docker to be up.
### (If we don't do this, Docker will not be responsive during the next step.)
system("while ! sudo -u docker docker version ; do sleep 2; done")

### BEGIN CLUSTERING ###

addresses = list(l.strip() for l in sys.stdin)

assert ipv4 in addresses

def makenames(addrs):
    return [ "node%s"%(i+1) for i in range(len(addrs)) ]

while addresses:
    cluster = addresses[:CLUSTER_SIZE]
    addresses = addresses[CLUSTER_SIZE:]
    if ipv4 not in cluster:
        continue
    names = makenames(cluster)
    for ipaddr, name in zip(cluster, names):
        system("grep ^{} /etc/hosts || echo {} {} | sudo tee -a /etc/hosts"
                    .format(ipaddr, ipaddr, name))
    print(cluster)

    mynode = cluster.index(ipv4) + 1
    system("echo node{} | sudo -u docker tee /tmp/node".format(mynode))
    system("echo node{} | sudo tee /etc/hostname".format(mynode))
    system("sudo hostname node{}".format(mynode))
    system("sudo -u docker mkdir -p /home/docker/.ssh")
    system("sudo -u docker touch /home/docker/.ssh/authorized_keys")

    if ipv4 == cluster[0]:
        # If I'm node1 and don't have a private key, generate one (with empty passphrase)
        system("sudo -u docker [ -f /home/docker/.ssh/id_rsa ] || sudo -u docker ssh-keygen -t rsa -f /home/docker/.ssh/id_rsa -P ''")

FINISH = time.time()
duration = "Initial deployment took {}s".format(str(FINISH - START)[:5])
system("echo {}".format(duration))
