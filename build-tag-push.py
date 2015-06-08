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

# Execute "docker-compose build" and abort if it fails.
subprocess.check_call(["docker-compose", "build"])

# Get the name of the current directory.
project_name = os.path.basename(os.path.realpath("."))

# Generate a Docker image tag, using the UNIX timestamp.
# (i.e. number of seconds since January 1st, 1970)
version = str(int(time.time()))

# Load the services from docker-compose.yml.
stack = yaml.load(open("docker-compose.yml"))

# Iterate over all services that have a "build" definition.
for service_name, service in stack.items():
    if "build" in service:
        compose_image = "{}_{}".format(project_name, service_name)
        hub_image = "{}/{}_{}:{}".format(user_name, project_name, service_name, version)
        # Re-tag the image so that it can be uploaded to the Docker Hub.
        subprocess.check_call(["docker", "tag", compose_image, hub_image])
        # Execute "docker push" to upload the image.
        subprocess.check_call(["docker", "push", hub_image])
        # Replace the "build" definition by an "image" definition,
        # using the name of the image on the Docker Hub.
        del service["build"]
        service["image"] = hub_image

# Write the new docker-compose.yml file.
new_compose_file = "docker-compose.yml-{}".format(version)
with open(new_compose_file, "w") as f:
    yaml.safe_dump(stack, f)

print("You can now use:")
print("docker-compose -f {}".format(new_compose_file))
