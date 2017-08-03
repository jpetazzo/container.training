# Setting up your own cluster 
If you want to go through this orchestration workshop on your own,
you will need a cluster of Docker nodes.

These instructions will walk you through the required steps,
using [Docker Machine](https://docs.docker.com/machine/) to
create the nodes.


## Requirements

You need Docker Machine. To check if it is installed, try to
run the following command:

```bash
$ docker-machine -v
docker-machine version 0.8.2, build e18a919
```

If you see a Docker Machine version number, perfect! Otherwise,
you need to install it; either as part of the Docker Toolbox,
or as a stand-alone tool. See [Docker Machine installation docs](
https://docs.docker.com/machine/install-machine/) for details.

You also need either credentials for a cloud provider, or a
local VirtualBox or VMware installation (or anything supported
by Docker Machine, really).


## Discrepancies with official environment

The resulting environment will be slightly different from the
one that we provision for people attending the workshop at
conferences and similar events, and you will have to adapt a
few things.

We try to list all the differences here.


### User name

The official environment uses user `docker`. If you use
Docker Machine, the user name will probably be different.

### Node aliases

In the official environment, aliases are seeded in
`/etc/hosts`, allowing you to resolve node IP addresses
with the aliases `node1`, `node2`, etc.; if you use
Docker Machine, you will have to lookup the IP addresses
with the `docker-machine ip nodeX` command instead.

### SSH keys

In the official environment, you can log from one node
to another with SSH, without having to provide a password,
thanks to pre-generated (and pre-copied) SSH keys.
If you use Docker Machine, you will have to use
`docker-machine ssh` from your machine instead.

### Machine and Compose

In the official environment, Docker Machine and Docker
Compose are installed on your nodes. If you use Docker
Machine you will have to install at least Docker Compose.

The easiest way to install Compose (verified to work
with the EC2 and VirtualBox drivers, and probably others
as well) is do use `docker-machine ssh` to connect
to your node, then run the following command:

```bash
sudo curl -L \
  https://github.com/docker/compose/releases/download/1.15.0/docker-compose-`uname -s`-`uname -m` \
  -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

Note that it is not necessary (or even useful) to
install Docker Machine on your nodes, since if you're
following that guide, you already have Machine on
your local computer. ☺


### IP addresses

In some environments, your nodes will have multiple
IP addresses. This is the case with VirtualBox, for
instance. At any point in the workshop, if you need
a node's IP address, you should use the address
given by the `docker-machine ip` command.


## Creating your nodes with Docker Machine

Here are some instructions for various Machine Drivers.


### AWS EC2

You have to retrieve your AWS access key and secret access key,
and set the following environment variables:

```bash
export MACHINE_DRIVER=amazonec2
export AWS_ACCESS_KEY_ID=AKI...
export AWS_SECRET_ACCESS_KEY=...
```

Optionally, you can also set `AWS_DEFAULT_REGION` to the region
closest to you. See [AWS documentation](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html#concepts-available-regions)
for the list of available regions and their codes.

For instance, if you are on the US West Coast, I recommend
that you set `AWS_DEFAULT_REGION` to `us-west-2`; if you are
in Europe, to `eu-central-1` (except in UK and Ireland where
you probably want `eu-west-1`), etc.

If you don't specify anything, your nodes will be in `us-east-1`.

You can also set `AWS_INSTANCE_TYPE` if you want bigger or smaller
instances than `t2.micro`. For the official workshops, we use
`m3.large`, but remember: the bigger the instance, the more
expensive it gets, obviously!

After setting these variables, run the following command:

```bash
for N in $(seq 1 5); do
  docker-machine create node$N
  docker-machine ssh node$N usermod -aG docker ubuntu
done
```

And after a few minutes, your five nodes will be ready. To log
into a node, use `docker-machine ssh nodeX`.

By default, Docker Machine places the created nodes in a
security group aptly named `docker-machine`. By default, this
group is pretty restrictive, and will only let you connect
to the Docker API and SSH. For the purpose of the workshop,
you will need to open that security group to normal traffic.
You can do that through the AWS EC2 console, or with the
following CLI command:

```bash
aws ec2 authorize-security-group-ingress --group-name docker-machine --protocol -1 --cidr 0.0.0.0/0
```

If Docker Machine fails, complaining that it cannot find
the default VPC or subnet, this could be because you have
an "old" EC2 account (created before the introduction of EC2
VPC) and your account has no default VPC. In that case,
you will have to create a VPC, a subnet in that VPC,
and use the corresponding Machine flags (`--amazonec2-vpc-id`
and `--amazonec2-subnet-id`) or environment variables
(`AWS_VPC_ID` and `AWS_SUBNET_ID`) to tell Machine what to use.

You will get similar error messages if you *have* set these
flags (or environment variables) but the VPC (or subnets)
indicated do not exist. This can happen if you frequently
switch between different EC2 accounts, and forget that you
have set the `AWS_VPC_ID` or `AWS_SUBNET_ID`.


### Microsoft Azure

You have to retrieve your subscription ID, and set the following environment
variables:

```bash
export MACHINE_DRIVER=azure
export AZURE_SUBSCRIPTION_ID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
```

Additionally, you can set `AZURE_LOCATION` to an Azure datacenter
close to you. By default, it will pick "West US". You can see
the available regions [on Azure's website](
https://azure.microsoft.com/en-us/regions/services/).
For instance, if you want to deploy on the US East Coast,
set `AZURE_LOCATION` to `East US` or `eastus` (capitalization
and spacing shouldn't matter; just use the names shown on the
map or table on Azure's website).

Then run the following command:

```bash
for N in $(seq 1 5); do
  docker-machine create node$N
  docker-machine ssh node$N usermod -aG docker docker-user
done
```

The CLI will give you instructions to authenticate on the Azure portal,
and once you've done that, it will create your VMs.

You will log into your nodes with `docker-machine ssh nodeX`.

By default, the firewall only allows access to the Docker API
and SSH ports. To open access to other ports, you can use the
following command:

```bash
for N in $(seq 1 5); do
az network nsg rule create -g docker-machine --name AllowAny --nsg-name node$N-firewall \
   --access allow --direction inbound --protocol '*' \
   --source-address-prefix '*' --source-port-range '*' \
   --destination-address-prefix '*' --destination-port-range '*'
done
```

(The command takes a while. Be patient.)


### Local VirtualBox or VMware Fusion

If you want to run with local VMs, set the environment variable
`MACHINE_DRIVER` to `virtualbox` or `vmwarefusion` and create your nodes:

```bash
export MACHINE_DRIVER=virtualbox
for N in $(seq 1 5); do
  docker-machine create node$N
done
```


### Terminating instances

When you're done, if you started your instance on a public
cloud (or anywhere where it costs you money!) you will want to
terminate (destroy) them. This can be done with the following
command:

```bash
for N in $(seq 1 5); do
  docker-machine rm -f node$N
done
```



