#!/usr/bin/env python

import os
import subprocess
import sys
import yaml

compose_file = os.environ.get("COMPOSE_FILE") or sys.argv[1]
stack = yaml.load(open(compose_file))

project_name = os.path.basename(os.path.realpath("."))

# Get all services in our compose application
containers_data = subprocess.check_output([
    "docker", "ps",
    "--filter", "label=com.docker.compose.project={}".format(project_name),
    "--format", '{{ .ID }} {{ .Label "com.docker.compose.service" }}',
])

# Get all existing ambassadors for this application
ambassadors_data = subprocess.check_output([
    "docker", "ps",
    "--filter", "label=ambassador.project={}".format(project_name),
    "--format", '{{ .ID }} '
                '{{ .Label "ambassador.container" }} '
                '{{ .Label "ambassador.service" }}',
])

# Build a set of existing ambassadors
ambassadors = dict()
for ambassador in ambassadors_data.split('\n'):
    if not ambassador:
        continue
    ambassador_id, container_id, linked_service = ambassador.split()
    ambassadors[container_id, linked_service] = ambassador_id

# Start the missing ambassadors
for container in containers_data.split('\n'):
    if not container:
        continue
    container_id, service_name = container.split()
    extra_hosts = stack[service_name].get("extra_hosts", {})
    for linked_service, bind_address in extra_hosts.items():
        description = "Ambassador {}/{}/{}".format(
            service_name, container_id, linked_service)
        ambassador_id = ambassadors.get((container_id, linked_service))
        if ambassador_id:
            print("{} already exists: {}".format(description, ambassador_id))
        else:
            print("{} not found, creating it:".format(description))
	    subprocess.check_call([
		"docker", "run", "-d",
		"--net", "container:{}".format(container_id),
		"--label", "ambassador.project={}".format(project_name),
		"--label", "ambassador.container={}".format(container_id),
		"--label", "ambassador.service={}".format(linked_service),
		"--label", "ambassador.bindaddr={}".format(bind_address),
		"jpetazzo/hamba", "run"
	    ])

