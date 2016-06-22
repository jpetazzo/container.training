import os
import subprocess
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

# Executes a bunch of commands in parallel, but no more than N at a time.
# This allows to execute concurrently a large number of tasks, without
# turning into a fork bomb.
# `parallelism` is the number of tasks to execute simultaneously.
# `commands` is a list of tasks to execute.
# Each task is itself a list, where the first element is a descriptive
# string, and the folloowing elements are the arguments to pass to Popen.
def parallel_run(commands, parallelism):
    running = []
    # While stuff is running, or we have stuff to run...
    while commands or running:
        # While there is stuff to run, and room in the pipe...
        while commands and len(running)<parallelism:
            command = commands.pop(0)
            print("START {}".format(command[0]))
            popen = subprocess.Popen(
                command[1:], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            popen._desc = command[0]
            running.append(popen)
        must_sleep = True
        for popen in running:
            status = popen.poll()
            if status is not None:
                must_sleep = False
                running.remove(popen)
                if status==0:
                    print("OK    {}".format(popen._desc))
                else:
                    print("ERROR {} [Exit status: {}]"
                          .format(popen._desc, status))
                    output = "\n" + popen.communicate()[0].strip()
                    output = output.replace("\n", "\n| ")
                    print(output)
        else:
            print("WAIT  ({} running, {} more to run)"
                  .format(len(running), len(commands)))
            if must_sleep:
                time.sleep(1)

