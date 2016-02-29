#!/usr/bin/env python

from common import parallel_run
import os
import subprocess

project_name = os.path.basename(os.path.realpath("."))

# Get all services and backends in our compose application.
containers_data = subprocess.check_output([
    "docker", "ps",
    "--filter", "label=com.docker.compose.project={}".format(project_name),
    "--format", '{{ .ID }} '
                '{{ .Label "com.docker.compose.service" }} '
                '{{ .Ports }}',
])

# Build list of backends.
frontend_ports = dict()
backends = dict()
for container in containers_data.split('\n'):
    if not container:
        continue
    # TODO: support services with multiple ports!
    container_id, service_name, port = container.split(' ')
    if not port:
        continue
    backend, frontend = port.split("->")
    backend_addr, backend_port = backend.split(':')
    frontend_port, frontend_proto = frontend.split('/')
    # TODO: deal with udp (mostly skip it?)
    assert frontend_proto == "tcp"
    # TODO: check inconsistencies between port mappings
    frontend_ports[service_name] = frontend_port
    if service_name not in backends:
        backends[service_name] = []
    backends[service_name].append((backend_addr, backend_port))

# Get all existing ambassadors for this application.
ambassadors_data = subprocess.check_output([
    "docker", "ps",
    "--filter", "label=ambassador.project={}".format(project_name),
    "--format", '{{ .ID }} '
                '{{ .Label "ambassador.service" }} '
                '{{ .Label "ambassador.bindaddr" }}',
])

# Update ambassadors.
operations = []
for ambassador in ambassadors_data.split('\n'):
    if not ambassador:
        continue
    ambassador_id, service_name, bind_address = ambassador.split()
    print("Updating configuration for {}/{} -> {}:{} -> {}"
          .format(service_name, ambassador_id,
                  bind_address, frontend_ports[service_name],
                  backends[service_name]))
    command = [
        ambassador_id,
        "docker", "run", "--rm", "--volumes-from", ambassador_id,
        "jpetazzo/hamba", "reconfigure",
        "{}:{}".format(bind_address, frontend_ports[service_name])
    ]
    for backend_addr, backend_port in backends[service_name]:
        command.extend([backend_addr, backend_port])
    operations.append(command)

# Execute all commands in parallel.
parallel_run(operations, 10)
