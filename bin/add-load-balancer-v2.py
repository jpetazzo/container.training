#!/usr/bin/env python

import os
import sys
import yaml

def error(msg):
    print("ERROR: {}".format(msg))
    exit(1)

# arg 1 = service name

service_name = sys.argv[1]

compose_file = os.environ["COMPOSE_FILE"]
input_file, output_file = compose_file, compose_file

config = yaml.load(open(input_file))

version = config.get("version")
if version != "2":
    error("Unsupported $COMPOSE_FILE version: {!r}".format(version))

# The load balancers need to know the service port to use.
# Those ports must be declared here.
ports = yaml.load(open("ports.yml"))

port = str(ports[service_name])

if service_name not in config["services"]:
    error("service {} not found in $COMPOSE_FILE"
          .format(service_name))

lb_name = "{}-lb".format(service_name)
be_name = "{}-be".format(service_name)
wd_name = "{}-wd".format(service_name)

if lb_name in config["services"]:
    error("load balancer {} already exists in $COMPOSE_FILE"
          .format(lb_name))

if wd_name in config["services"]:
    error("dns watcher {} already exists in $COMPOSE_FILE"
          .format(wd_name))

service = config["services"][service_name]
if "networks" in service:
    error("service {} has custom networks"
          .format(service_name))

# Put the service on its own network.
service["networks"] = {service_name: {"aliases": [ be_name ] } }
# Put a label indicating which load balancer is responsible for this service.
if "labels" not in service:
    service["labels"] = {}
service["labels"]["loadbalancer"] = lb_name

# Add the load balancer.
config["services"][lb_name] = {
    "image": "jpetazzo/hamba",
    "command": "{} {} {}".format(port, be_name, port),
    "depends_on": [ service_name ],
    "networks": {
        "default": {
            "aliases": [ service_name ],
        },
        service_name: None,
    },
}

# Add the DNS watcher.
config["services"][wd_name] = {
    "image": "jpetazzo/watchdns",
    "command": "{} {} {}".format(port, be_name, port),
    "volumes_from": [ lb_name ],
    "networks": {
      service_name: None,
    },
}

if "networks" not in config:
    config["networks"] = {}
if service_name not in config["networks"]:
    config["networks"][service_name] = None

yaml.safe_dump(config, open(output_file, "w"), default_flow_style=False)

