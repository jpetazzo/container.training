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

subprocess.check_call(["docker-compose", "build"])

project_name = os.path.basename(os.path.realpath("."))

version = str(int(time.time()))

stack = yaml.load(open("docker-compose.yml"))
for service_name, service in stack.items():
    if "build" in service:
        compose_image = "{}_{}".format(project_name, service_name)
        hub_image = "{}/{}_{}:{}".format(user_name, project_name, service_name, version)
        subprocess.check_call(["docker", "tag", compose_image, hub_image])
        subprocess.check_call(["docker", "push", hub_image])

