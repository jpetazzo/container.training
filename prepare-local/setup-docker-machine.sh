#!/bin/sh

/usr/local/bin/docker-machine create -d generic --generic-ip-address "10.10.10.20" --generic-ssh-user vagrant --generic-ssh-port 22 --generic-ssh-key /home/vagrant/private-key --generic-engine-port 55555 "node2"
/usr/local/bin/docker-machine create -d generic --generic-ip-address "10.10.10.30" --generic-ssh-user vagrant --generic-ssh-port 22 --generic-ssh-key /home/vagrant/private-key --generic-engine-port 55555 "node3"
/usr/local/bin/docker-machine create -d generic --generic-ip-address "10.10.10.40" --generic-ssh-user vagrant --generic-ssh-port 22 --generic-ssh-key /home/vagrant/private-key --generic-engine-port 55555 "node4"
/usr/local/bin/docker-machine create -d generic --generic-ip-address "10.10.10.50" --generic-ssh-user vagrant --generic-ssh-port 22 --generic-ssh-key /home/vagrant/private-key --generic-engine-port 55555 "node5"
