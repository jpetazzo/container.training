#!/usr/bin/env python

from common import ComposeFile
import yaml

config = ComposeFile()

# The ambassadors need to know the service port to use.
# Those ports must be declared here.
ports = yaml.load(open("ports.yml"))

def generate_local_addr():
    last_byte = 2
    while last_byte<255:
        yield "127.127.0.{}".format(last_byte)
        last_byte += 1

for service_name, service in config.services.items():
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

config.save()
