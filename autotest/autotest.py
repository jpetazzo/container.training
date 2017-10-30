#!/usr/bin/env python

import uuid
import logging
import os
import re
import subprocess
import sys
import time
import uuid

logging.basicConfig(level=logging.DEBUG)


TIMEOUT = 60 # 1 minute


def hrule():
    return "="*int(subprocess.check_output(["tput", "cols"]))

# A "snippet" is something that the user is supposed to do in the workshop.
# Most of the "snippets" are shell commands.
# Some of them can be key strokes or other actions.
# In the markdown source, they are the code sections (identified by triple-
# quotes) within .exercise[] sections.

class Snippet(object):

    def __init__(self, slide, content):
        self.slide = slide
        self.content = content
        self.actions = []

    def __str__(self):
        return self.content


class Slide(object):

    current_slide = 0

    def __init__(self, content):
        Slide.current_slide += 1
        self.number = Slide.current_slide

        # Remove commented-out slides
        # (remark.js considers ??? to be the separator for speaker notes)
        content = re.split("\n\?\?\?\n", content)[0]
        self.content = content

        self.snippets = []
        exercises = re.findall("\.exercise\[(.*)\]", content, re.DOTALL)
        for exercise in exercises:
            if "```" in exercise:
                for snippet in exercise.split("```")[1::2]:
                    self.snippets.append(Snippet(self, snippet))
            else:
                logging.warning("Exercise on slide {} does not have any ``` snippet."
                                .format(self.number))
                self.debug()

    def __str__(self):
        text = self.content
        for snippet in self.snippets:
            text = text.replace(snippet.content, ansi("7")(snippet.content))
        return text

    def debug(self):
        logging.debug("\n{}\n{}\n{}".format(hrule(), self.content, hrule()))


def ansi(code):
    return lambda s: "\x1b[{}m{}\x1b[0m".format(code, s)


def wait_for_string(s):
    logging.debug("Waiting for string: {}".format(s))
    deadline = time.time() + TIMEOUT
    while time.time() < deadline:
        output = subprocess.check_output(["tmux", "capture-pane", "-p"])
        if s in output:
            return
        time.sleep(1)
    raise Exception("Timed out while waiting for {}!".format(s))


def wait_for_prompt():
    logging.debug("Waiting for prompt.")
    deadline = time.time() + TIMEOUT
    while time.time() < deadline:
        output = subprocess.check_output(["tmux", "capture-pane", "-p"])
        if output[-3:-1] == "\n$":
            return
        time.sleep(1)
    raise Exception("Timed out while waiting for prompt!".format(s))


def check_exit_status():
    token = uuid.uuid4().hex
    data = "echo {} $?\n".format(token)
    logging.debug("Sending {!r} to get exit status.".format(data))
    subprocess.check_call(["tmux", "send-keys", data])
    time.sleep(0.5)
    wait_for_prompt()
    screen = subprocess.check_output(["tmux", "capture-pane", "-p"])
    status = re.findall("\n{} ([0-9]+)\n".format(token), screen, re.MULTILINE)
    logging.debug("Got exit status: {}.".format(status))
    if len(status) == 0:
        raise Exception("Couldn't retrieve status code {}. Timed out?".format(token))
    if len(status) > 1:
        raise Exception("More than one status code {}. I'm seeing double! Shoot them both.".format(token))
    code = int(status[0])
    if code != 0:
        raise Exception("Non-zero exit status: {}.".format(code))
    # Otherwise just return peacefully.


slides = []
content = open(sys.argv[1]).read()
for slide in re.split("\n---?\n", content):
    slides.append(Slide(slide))

actions = []
for slide in slides:
    for snippet in slide.snippets:
        content = snippet.content
        # Extract the "method" (e.g. bash, keys, ...)
        # On multi-line snippets, the method is alone on the first line
        # On single-line snippets, the data follows the method immediately
        if '\n' in content:
            method, data = content.split('\n', 1)
        else:
            method, data = content.split(' ', 1)
        actions.append((slide, snippet, method, data))


try:
    i = int(open("nextstep").read())
    logging.info("Loaded next step ({}) from file.".format(i))
except Exception as e:
    logging.warning("Could not read nextstep file ({}), initializing to 0.".format(e))
    i = 0


keymaps = { "^C": "\x03" }

interactive = True

while i < len(actions):
    with open("nextstep", "w") as f:
        f.write(str(i))
    slide, snippet, method, data = actions[i]

    data = data.strip()

    print(hrule())
    print(slide.content.replace(snippet.content, ansi(7)(snippet.content)))
    print(hrule())
    if interactive:
        print("[{}] Shall we execute that snippet above?".format(i))
        print("(ENTER to execute, 'c' to continue until next error, N to jump to step #N)")
        command = raw_input("> ")
    else:
        command = ""

    if command == "c":
        # continue until next timeout
        interactive = False
    elif command.isdigit():
        i = int(command)
    elif command == "":
        logging.info("Running with method {}: {}".format(method, data))
        if method == "keys":
            if data in keymaps:
                print("Mapping {!r} to {!r}.".format(data, keymaps[data]))
                data = keymaps[data]
            subprocess.check_call(["tmux", "send-keys", data])
        elif method == "bash":
            # Make sure that we're ready
            wait_for_prompt()
            # Strip leading spaces
            data = re.sub("\n +", "\n", data)
            # Add "RETURN" at the end of the command :)
            data += "\n"
            # Send command
            subprocess.check_call(["tmux", "send-keys", data])
            # Force a short sleep to avoid race condition
            time.sleep(0.5)
            _, _, next_method, next_data = actions[i+1]
            if next_method == "wait":
                wait_for_string(next_data)
            else:
                wait_for_prompt()
                # Verify return code FIXME should be optional
                check_exit_status()
        else:
            logging.warning("Unknown method {}: {!r}".format(method, data))
        i += 1

    else:
        i += 1
        logging.warning("Unknown command {}, skipping to next step.".format(command))

# Reset slide counter
with open("nextstep", "w") as f:
    f.write(str(0))
