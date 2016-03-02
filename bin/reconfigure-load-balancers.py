#!/usr/bin/env python

# FIXME: hardcoded
PORT="80"

import os
import subprocess

project_name = os.path.basename(os.path.realpath("."))

# Get all existing services for this application.
containers_data = subprocess.check_output([
    "docker", "ps",
    "--filter", "label=com.docker.compose.project={}".format(project_name),
    "--format", '{{ .Label "com.docker.compose.service" }} '
                '{{ .Label "com.docker.compose.container-number" }} '
                '{{ .Label "loadbalancer" }}',
])

load_balancers = dict()
for line in containers_data.split('\n'):
    if not line:
        continue
    service_name, container_number, load_balancer = line.split(' ')
    if load_balancer:
        if load_balancer not in load_balancers:
            load_balancers[load_balancer] = []
        load_balancers[load_balancer].append((service_name, int(container_number)))

for load_balancer, backends in load_balancers.items():
    # FIXME: iterate on all load balancers
    container_name = "{}_{}_1".format(project_name, load_balancer)
    command = [
        "docker", "run", "--rm",
        "--volumes-from", container_name,
        "--net", "container:{}".format(container_name),
        "jpetazzo/hamba", "reconfigure", PORT,
    ]
    command.extend(
        "{}_{}_{}:{}".format(project_name, backend_name, backend_number, PORT)
        for (backend_name, backend_number) in sorted(backends)
    )
    print("Updating configuration for {} with {} backend(s)..."
          .format(container_name, len(backends)))
    subprocess.check_output(command)

