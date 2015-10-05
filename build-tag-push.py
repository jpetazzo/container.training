#!/usr/bin/env python

import os
import subprocess
import time
import yaml

user_name = os.environ.get("DOCKERHUB_USER")

if not user_name:
    print("Please set the DOCKERHUB_USER to your user name, e.g.:")
    print("export DOCKERHUB_USER=zoe")
    exit(1)

# Get the name of the current directory.
project_name = os.path.basename(os.path.realpath("."))

# Generate a Docker image tag, using the UNIX timestamp.
# (i.e. number of seconds since January 1st, 1970)
version = str(int(time.time()))

input_file = os.environ.get(
    "DOCKER_COMPOSE_YML", "docker-compose.yml")
output_file = os.environ.get(
    "DOCKER_COMPOSE_YML", "docker-compose.yml-{}".format(version))

if input_file == output_file == "docker-compose.yml":
    print("I will not clobber your docker-compose.yml file.")
    print("Unset DOCKER_COMPOSE_YML or set it to something else.")
    exit(1)

print("Input file: {}".format(input_file))
print("Output file: {}".format(output_file))

# Execute "docker-compose build" and abort if it fails.
subprocess.check_call(["docker-compose", "-f", input_file, "build"])

# Load the services from the input docker-compose.yml file.
# TODO: run parallel builds.
stack = yaml.load(open(input_file))

# Iterate over all services that have a "build" definition.
# Tag them, and initiate a push in the background.
push_operations = dict()
for service_name, service in stack.items():
    if "build" in service:
        compose_image = "{}_{}".format(project_name, service_name)
        hub_image = "{}/{}_{}:{}".format(user_name, project_name, service_name, version)
        # Re-tag the image so that it can be uploaded to the Docker Hub.
        subprocess.check_call(["docker", "tag", compose_image, hub_image])
        # Spawn "docker push" to upload the image.
        push_operations[service_name] = subprocess.Popen(["docker", "push", hub_image])
        # Replace the "build" definition by an "image" definition,
        # using the name of the image on the Docker Hub.
        del service["build"]
        service["image"] = hub_image

# Wait for push operations to complete.
for service_name, popen_object in push_operations.items():
    print("Waiting for {} push to complete...".format(service_name))
    popen_object.wait()
    print("Done.")

# Write the new docker-compose.yml file.
with open(output_file, "w") as f:
    yaml.safe_dump(stack, f, default_flow_style=False)

print("Wrote new compose file.")
print("COMPOSE_FILE={}".format(output_file))
