#!/usr/bin/env python

import os
import sys
import yaml

# arg 1 = service name
# arg 2 = number of instances

service_name = sys.argv[1]
desired_instances = int(sys.argv[2])

compose_file = os.environ["COMPOSE_FILE"]
input_file, output_file = compose_file, compose_file

config = yaml.load(open(input_file))

# The ambassadors need to know the service port to use.
# Those ports must be declared here.
ports = yaml.load(open("ports.yml"))

port = str(ports[service_name])

command_line = port

depends_on = []

for n in range(1, 1+desired_instances):
    config["services"]["{}{}".format(service_name, n)] = config["services"][service_name]
    command_line += " {}{}:{}".format(service_name, n, port)
    depends_on.append("{}{}".format(service_name, n))

config["services"][service_name] = {
    "image": "jpetazzo/hamba",
    "command": command_line,
    "depends_on": depends_on,
}
if "networks" in config["services"]["{}1".format(service_name)]:
    config["services"][service_name]["networks"] = config["services"]["{}1".format(service_name)]["networks"]

yaml.safe_dump(config, open(output_file, "w"), default_flow_style=False)

