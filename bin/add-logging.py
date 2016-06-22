#!/usr/bin/env python

import os
import sys
import yaml

def error(msg):
    print("ERROR: {}".format(msg))
    exit(1)

compose_file = os.environ["COMPOSE_FILE"]
input_file, output_file = compose_file, compose_file

config = yaml.load(open(input_file))

version = config.get("version")
if version != "2":
    error("Unsupported $COMPOSE_FILE version: {!r}".format(version))

for service in config["services"]:
    config["services"][service]["logging"] = dict(
        driver="gelf",
        options={"gelf-address": "udp://localhost:12201"},
        )

yaml.safe_dump(config, open(output_file, "w"), default_flow_style=False)

