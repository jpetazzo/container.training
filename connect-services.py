#!/usr/bin/env python

import os
import subprocess
import sys
import yaml

stack = yaml.load(open(sys.argv[1]))

ports = yaml.load(open("ports.yml"))

project_name = os.path.basename(os.path.realpath("."))

ambassadors = {}

service_instances = {}

# Generate container names for all instances
for service_name in stack:
    service_instances[service_name] = []
    n = 0
    while True:
        n += 1
        try:
            container_name = "{}_{}_{}".format(project_name, service_name, n)
            subprocess.check_call(
                [ "docker", "inspect", container_name ],
                stderr=open("/dev/null","a")
            )
            service_instances[service_name].append(container_name)
        except subprocess.CalledProcessError:
            break

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
        for container_name in service_instances[link_name]:
            endpoint = subprocess.check_output(
                ["docker", "port", container_name, port]
            )
        endpoints.append(port)
        print("Endpoints found for {}->{}:".format(service_name, link_name))
        print(endpoints)
        for container_name in service_instances[service_name]:
            ambassador = {}
            ambassador["image"] = "jpetazzo/hamba"
            ambassador["net"] = "container:"+container_name
            command = "{}:{}".format(link_addr, port)
            for endpoint in endpoints:
                command = command + " {} {}".format(endpoint.split(':'))
            ambassador["command"] = command
            n = len(ambassadors)
            ambassadors["amba{}".format(n)] = ambassador

yaml.safe_dump(open("ambassadors.yml", "w"))
