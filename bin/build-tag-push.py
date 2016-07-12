#!/usr/bin/env python

from common import ComposeFile
import os
import subprocess
import time

registry = os.environ.get("DOCKER_REGISTRY")

if not registry:
    print("Please set the DOCKER_REGISTRY variable, e.g.:")
    print("export DOCKER_REGISTRY=jpetazzo # use the Docker Hub")
    print("export DOCKER_REGISTRY=localhost:5000 # use a local registry")
    exit(1)

# Get the name of the current directory.
project_name = os.path.basename(os.path.realpath("."))

# Version used to tag the generated Docker image, using the UNIX timestamp or the given version.
if "VERSION" not in os.environ:
    version = str(int(time.time()))
else:
    version = os.environ["VERSION"]

# Execute "docker-compose build" and abort if it fails.
subprocess.check_call(["docker-compose", "-f", "docker-compose.yml", "build"])

# Load the services from the input docker-compose.yml file.
# TODO: run parallel builds.
compose_file = ComposeFile("docker-compose.yml")

# Iterate over all services that have a "build" definition.
# Tag them, and initiate a push in the background.
push_operations = dict()
for service_name, service in compose_file.services.items():
    if "build" in service:
        compose_image = "{}_{}".format(project_name, service_name)
        registry_image = "{}/{}:{}".format(registry, compose_image, version)
        # Re-tag the image so that it can be uploaded to the registry.
        subprocess.check_call(["docker", "tag", compose_image, registry_image])
        # Spawn "docker push" to upload the image.
        push_operations[service_name] = subprocess.Popen(["docker", "push", registry_image])
        # Replace the "build" definition by an "image" definition,
        # using the name of the image on the registry.
        del service["build"]
        service["image"] = registry_image

# Wait for push operations to complete.
for service_name, popen_object in push_operations.items():
    print("Waiting for {} push to complete...".format(service_name))
    popen_object.wait()
    print("Done.")

# Write the new docker-compose.yml file.
if "COMPOSE_FILE" not in os.environ:
    os.environ["COMPOSE_FILE"] = "docker-compose.yml-{}".format(version)
    print("Writing to new Compose file:")
else:
    print("Writing to provided Compose file:")

print("COMPOSE_FILE={}".format(os.environ["COMPOSE_FILE"]))
compose_file.save()

