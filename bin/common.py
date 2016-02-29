import os
import sys
import time
import yaml


def COMPOSE_FILE():
    if "COMPOSE_FILE" not in os.environ:
        print("The $COMPOSE_FILE environment variable is not set. Aborting.")
        exit(1)
    return os.environ["COMPOSE_FILE"]


class ComposeFile(object):

    def __init__(self, filename=None):
        if filename is None:
            filename = COMPOSE_FILE()
        if not os.path.isfile(filename):
            print("File {!r} does not exist. Aborting.".format(filename))
            exit(1)
        self.data = yaml.load(open(filename))

    @property
    def services(self):
        if self.data.get("version") == "2":
            return self.data["services"]
        else:
            return self.data

    def save(self, filename=None):
        if filename is None:
            filename = COMPOSE_FILE()
        with open(filename, "w") as f:
            yaml.safe_dump(self.data, f, default_flow_style=False)

