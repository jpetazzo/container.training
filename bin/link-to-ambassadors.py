#!/usr/bin/env python

import os
import sys
import yaml

# You can specify up to 2 parameters:
# - with 0 parameter, we will look for the COMPOSE_FILE env var
# - with 1 parameter, the same file will be used for in and out
# - with 2 parameters, the 1st is the input, the 2nd the output
if len(sys.argv)==1:
    if "COMPOSE_FILE" not in os.environ:
        print("Please specify 1 or 2 file names, or set COMPOSE_FILE.")
        sys.exit(1)
    compose_file = os.environ["COMPOSE_FILE"]
    if compose_file == "docker-compose.yml":
        print("Refusing to operate directly on docker-compose.yml.")
        print("Specify it on the command-line if that's what you want.")
        sys.exit(1)
    input_file, output_file = compose_file, compose_file
elif len(sys.argv)==2:
    input_file, output_file = sys.argv[1], sys.argv[1]
elif len(sys.argv)==3:
    input_file, output_file = sys.argv[1], sys.argv[2]
else:
    print("Too many arguments. Please specify up to 2 file names.")
    sys.exit(1)

stack = yaml.load(open(input_file))

# The ambassadors need to know the service port to use.
# Those ports must be declared here.
ports = yaml.load(open("ports.yml"))

def generate_local_addr():
    last_byte = 2
    while last_byte<255:
        yield "127.127.0.{}".format(last_byte)
        last_byte += 1

for service_name, service in stack.items():
    if "links" in service:
        for link, local_addr in zip(service["links"], generate_local_addr()):
            if link not in ports:
                print("Skipping link {} in service {} "
                      "(no port mapping defined). "
                      "Your code will probably break."
                      .format(link, service_name))
                continue
            if "extra_hosts" not in service:
                service["extra_hosts"] = {}
            service["extra_hosts"][link] = local_addr
        del service["links"]
    if "ports" in service:
        del service["ports"]
    if "volumes" in service:
        del service["volumes"]
    if service_name in ports:
        service["ports"] = [ ports[service_name] ]

yaml.safe_dump(stack, open(output_file, "w"), default_flow_style=False)

