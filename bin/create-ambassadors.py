#!/usr/bin/env python

from common import ComposeFile, parallel_run
import os
import subprocess

config = ComposeFile()

project_name = os.path.basename(os.path.realpath("."))

# Get all services in our compose application.
containers_data = subprocess.check_output([
    "docker", "ps",
    "--filter", "label=com.docker.compose.project={}".format(project_name),
    "--format", '{{ .ID }} {{ .Label "com.docker.compose.service" }}',
])

# Get all existing ambassadors for this application.
ambassadors_data = subprocess.check_output([
    "docker", "ps",
    "--filter", "label=ambassador.project={}".format(project_name),
    "--format", '{{ .ID }} '
                '{{ .Label "ambassador.container" }} '
                '{{ .Label "ambassador.service" }}',
])

# Build a set of existing ambassadors.
ambassadors = dict()
for ambassador in ambassadors_data.split('\n'):
    if not ambassador:
        continue
    ambassador_id, container_id, linked_service = ambassador.split()
    ambassadors[container_id, linked_service] = ambassador_id

operations = []

# Start the missing ambassadors.
for container in containers_data.split('\n'):
    if not container:
        continue
    container_id, service_name = container.split()
    extra_hosts = config.services[service_name].get("extra_hosts", {})
    for linked_service, bind_address in extra_hosts.items():
        description = "Ambassador {}/{}/{}".format(
            service_name, container_id, linked_service)
        ambassador_id = ambassadors.pop((container_id, linked_service), None)
        if ambassador_id:
            print("{} already exists: {}".format(description, ambassador_id))
        else:
            print("{} not found, creating it.".format(description))
	    operations.append([
                description,
		"docker", "run", "-d",
		"--net", "container:{}".format(container_id),
		"--label", "ambassador.project={}".format(project_name),
		"--label", "ambassador.container={}".format(container_id),
		"--label", "ambassador.service={}".format(linked_service),
		"--label", "ambassador.bindaddr={}".format(bind_address),
		"jpetazzo/hamba", "run"
	    ])

# Destroy extraneous ambassadors.
for ambassador_id in ambassadors.values():
    print("{} is not useful anymore, destroying it.".format(ambassador_id))
    operations.append([
        "rm -f {}".format(ambassador_id),
        "docker", "rm", "-f", ambassador_id,
    ])

# Execute all commands in parallel.
parallel_run(operations, 10)
