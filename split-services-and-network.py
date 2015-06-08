#!/usr/bin/env python

import sys
import yaml

input_file, output_file = sys.argv[1:3]

stack = yaml.load(open(input_file))

# The ambassadors need to know the service port to use.
# Those ports must be declared here.
ports = dict(
    redis=6379,
    rng=80,
    hasher=80,
    )

# Links are stored as {from: [to, to, ...]}.
links = {}

# First, collect all links.
for service_name, service in stack.items():
    if "links" in service:
        for link in service["links"]:
            if link not in ports:
                print("Skipping link {} in service {} "
                      "(no port mapping defined). "
                      "Your code will probably break."
                      .format(link, service_name))
                continue
            if service_name not in links:
                links[service_name] = []
            links[service_name].append(link)
        del service["links"]
    if "ports" in service:
        del service["ports"]

yaml.safe_dump(stack, open(output_file, "w"))

