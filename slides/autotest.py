#!/usr/bin/env python

import logging
import os
import random
import re
import subprocess
import sys
import time
import uuid

logging.basicConfig(level=os.environ.get("LOG_LEVEL", "INFO"))


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


def wait_for_string(s, timeout=TIMEOUT):
    logging.debug("Waiting for string: {}".format(s))
    deadline = time.time() + timeout
    while time.time() < deadline:
        output = capture_pane()
        if s in output:
            return
        time.sleep(1)
    raise Exception("Timed out while waiting for {}!".format(s))


def wait_for_prompt():
    logging.debug("Waiting for prompt.")
    deadline = time.time() + TIMEOUT
    while time.time() < deadline:
        output = capture_pane()
        # If we are not at the bottom of the screen, there will be a bunch of extra \n's
        output = output.rstrip('\n')
        if output.endswith("\n$"):
            return
        if output.endswith("\n/ #"):
            return
        time.sleep(1)
    raise Exception("Timed out while waiting for prompt!")


def check_exit_status():
    if not verify_status:
        return
    token = uuid.uuid4().hex
    data = "echo {} $?\n".format(token)
    logging.debug("Sending {!r} to get exit status.".format(data))
    send_keys(data)
    time.sleep(0.5)
    wait_for_prompt()
    screen = capture_pane()
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


def setup_tmux_and_ssh():
    if subprocess.call(["tmux", "has-session"]):
        logging.info("Couldn't connect to tmux. A new tmux session will be created.")
        subprocess.check_call(["tmux", "new-session", "-d"])
        wait_for_string("$")
        send_keys("cd ../prepare-vms\n")
        send_keys("ssh docker@$(head -n1 ips.txt)\n")
        wait_for_string("password:")
        send_keys("training\n")
        wait_for_prompt()
    else:
        logging.info("Found tmux session. Trying to acquire shell prompt.")
        wait_for_prompt()
    logging.info("Successfully connected to test cluster in tmux session.")



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


def send_keys(data):
    if simulate_type and data[0] != '^':
        for key in data:
            if key == ";":
                key = "\\;"
            subprocess.check_call(["tmux", "send-keys", key])
            time.sleep(0.1*random.random())
    else:
        subprocess.check_call(["tmux", "send-keys", data])

def capture_pane():
    return subprocess.check_output(["tmux", "capture-pane", "-p"])


setup_tmux_and_ssh()


try:
    i = int(open("nextstep").read())
    logging.info("Loaded next step ({}) from file.".format(i))
except Exception as e:
    logging.warning("Could not read nextstep file ({}), initializing to 0.".format(e))
    i = 0

interactive = True
verify_status = False
simulate_type = True

while i < len(actions):
    with open("nextstep", "w") as f:
        f.write(str(i))
    slide, snippet, method, data = actions[i]

    # Remove extra spaces (we don't want them in the terminal) and carriage returns
    data = data.strip()

    print(hrule())
    print(slide.content.replace(snippet.content, ansi(7)(snippet.content)))
    print(hrule())
    if interactive:
        print("[{}/{}] Shall we execute that snippet above?".format(i, len(actions)))
        print("(ENTER to execute, 'c' to continue until next error, N to jump to step #N)")
        command = raw_input("> ")
    else:
        command = ""

    # For now, remove the `highlighted` sections
    # (Make sure to use $() in shell snippets!)
    if '`' in data:
        logging.info("Stripping ` from snippet.")
        data = data.replace('`', '')

    if command == "c":
        # continue until next timeout
        interactive = False
    elif command.isdigit():
        i = int(command)
    elif command == "":
        logging.info("Running with method {}: {}".format(method, data))
        if method == "keys":
            send_keys(data)
        elif method == "bash":
            # Make sure that we're ready
            wait_for_prompt()
            # Strip leading spaces
            data = re.sub("\n +", "\n", data)
            # Add "RETURN" at the end of the command :)
            data += "\n"
            # Send command
            send_keys(data)
            # Force a short sleep to avoid race condition
            time.sleep(0.5)
            _, _, next_method, next_data = actions[i+1]
            if next_method == "wait":
                wait_for_string(next_data)
            elif next_method == "longwait":
                wait_for_string(next_data, 10*TIMEOUT)
            else:
                wait_for_prompt()
                # Verify return code FIXME should be optional
                check_exit_status()
        elif method == "copypaste":
            screen = capture_pane()
            matches = re.findall(data, screen, flags=re.DOTALL)
            if len(matches) == 0:
                raise Exception("Could not find regex {} in output.".format(data))
            # Arbitrarily get the most recent match
            match = matches[-1]
            # Remove line breaks (like a screen copy paste would do)
            match = match.replace('\n', '')
            send_keys(match + '\n')
            # FIXME: we should factor out the "bash" method
            wait_for_prompt()
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
