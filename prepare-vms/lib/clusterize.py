#!/usr/bin/env python
import os
import sys
import time
import yaml

#################################

config = yaml.load(open("/tmp/settings.yaml"))
CLUSTER_SIZE = config["clustersize"]
CLUSTER_PREFIX = config["clusterprefix"]

#################################

# This script will be run as ubuntu user, which has root privileges.

STEP = 0

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
    with open(os.environ["HOME"] + "/.bash_history", "a") as f:
        f.write("{}\n".format(cmd))
    if retcode != 0:
        msg = "The following command failed with exit code {}:\n".format(retcode)
        msg+= cmd
        raise(Exception(msg))

# Get our public IP address
# ipv4_retrieval_endpoint = "http://169.254.169.254/latest/meta-data/public-ipv4"
ipv4_retrieval_endpoint = "http://myip.enix.org/REMOTE_ADDR"
system("curl --silent {} > /tmp/ipv4".format(ipv4_retrieval_endpoint))
ipv4 = open("/tmp/ipv4").read()
system("echo HOSTIP={} | sudo tee -a /etc/environment".format(ipv4))

### BEGIN CLUSTERING ###

addresses = list(l.strip() for l in sys.stdin)

assert ipv4 in addresses

def makenames(addrs):
    return [ "%s%s"%(CLUSTER_PREFIX, i+1) for i in range(len(addrs)) ]

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
    system("echo {}{} | sudo tee /etc/hostname".format(CLUSTER_PREFIX, mynode))
    system("sudo hostname {}{}".format(CLUSTER_PREFIX, mynode))

    # Record the IPV4 and name of the first node
    system("echo {} | sudo tee /etc/ipv4_of_first_node".format(cluster[0]))
    system("echo {} | sudo tee /etc/name_of_first_node".format(names[0]))

    # Create a convenience file to easily check if we're the first node
    if ipv4 == cluster[0]:
        system("sudo ln -sf /bin/true /usr/local/bin/i_am_first_node")
    else:
        system("sudo ln -sf /bin/false /usr/local/bin/i_am_first_node")
