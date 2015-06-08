#!/usr/bin/env python

import os
import subprocess
import sys
import yaml

stack = yaml.load(open(sys.argv[1]))

ports = yaml.load(open("ports.yml"))

project_name = os.path.basename(os.path.realpath("."))

for service_name, service in stack.items():
    extra_hosts = service.get("extra_hosts", {})
    for link_name, link_addr in extra_hosts.items():
        if link_name not in ports:
            print("Skipping link {} in service {} "
                  "(no port mapping defined). "
                  "Your code will probably break."
                  .format(link, service_name))
            continue
        port = ports[link_name]
        endpoints = []
        n = 1
        while True:
            try:
                container_name = "{}_{}_{}".format(project_name, link_name, n)
                endpoint.append(subprocess.check_output([
                                    "docker", "port", container_name, str(port)]))
            except OSError:
                break
        print("Endpoints found for {}->{}:".format(service_name, link_name))
        print(endpoints)

