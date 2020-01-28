#!/usr/bin/env python
# coding: utf-8

import click
import logging
import os
import random
import re
import select
import subprocess
import sys
import time
import uuid
import yaml


logging.basicConfig(level=os.environ.get("LOG_LEVEL", "INFO"))


TIMEOUT = 60 # 1 minute

# This one is not a constant. It's an ugly global.
IPADDR = None


class State(object):

    def __init__(self):
        self.clipboard = ""
        self.interactive = True
        self.verify_status = True
        self.simulate_type = False
        self.switch_desktop = False
        self.sync_slides = False
        self.open_links = False
        self.run_hidden = True
        self.slide = 1
        self.snippet = 0

    def load(self):
        data = yaml.load(open("state.yaml"))
        self.clipboard = str(data["clipboard"])
        self.interactive = bool(data["interactive"])
        self.verify_status = bool(data["verify_status"])
        self.simulate_type = bool(data["simulate_type"])
        self.switch_desktop = bool(data["switch_desktop"])
        self.sync_slides = bool(data["sync_slides"])
        self.open_links = bool(data["open_links"])
        self.run_hidden = bool(data["run_hidden"])
        self.slide = int(data["slide"])
        self.snippet = int(data["snippet"])

    def save(self):
        with open("state.yaml", "w") as f:
            yaml.dump(dict(
                clipboard=self.clipboard,
                interactive=self.interactive,
                verify_status=self.verify_status,
                simulate_type=self.simulate_type,
                switch_desktop=self.switch_desktop,
                sync_slides=self.sync_slides,
                open_links=self.open_links,
                run_hidden=self.run_hidden,
                slide=self.slide,
                snippet=self.snippet,
                ), f, default_flow_style=False)


state = State()


outfile = open("autopilot.log", "w")

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
        # Extract the "method" (e.g. bash, keys, ...)
        # On multi-line snippets, the method is alone on the first line
        # On single-line snippets, the data follows the method immediately
        if '\n' in content:
            self.method, self.data = content.split('\n', 1)
            self.data = self.data.strip()
        elif ' ' in content:
            self.method, self.data = content.split(' ', 1)
        else:
            self.method, self.data = content, None
        self.next = None

    def __str__(self):
        return self.content


class Slide(object):

    current_slide = 0

    def __init__(self, content):
        self.number = Slide.current_slide
        Slide.current_slide += 1

        # Remove commented-out slides
        # (remark.js considers ??? to be the separator for speaker notes)
        content = re.split("\n\?\?\?\n", content)[0]
        self.content = content

        self.snippets = []
        exercises = re.findall("\.exercise\[(.*)\]", content, re.DOTALL)
        for exercise in exercises:
            if "```" in exercise:
                previous = None
                for snippet_content in exercise.split("```")[1::2]:
                    snippet = Snippet(self, snippet_content)
                    if previous:
                        previous.next = snippet
                    previous = snippet
                    self.snippets.append(snippet)
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


def focus_slides():
    if not state.switch_desktop:
        return
    subprocess.check_output(["i3-msg", "workspace", "3"])
    subprocess.check_output(["i3-msg", "workspace", "1"])

def focus_terminal():
    if not state.switch_desktop:
        return
    subprocess.check_output(["i3-msg", "workspace", "2"])
    subprocess.check_output(["i3-msg", "workspace", "1"])

def focus_browser():
    if not state.switch_desktop:
        return
    subprocess.check_output(["i3-msg", "workspace", "4"])
    subprocess.check_output(["i3-msg", "workspace", "1"])


def ansi(code):
    return lambda s: "\x1b[{}m{}\x1b[0m".format(code, s)


# Sleeps the indicated delay, but interruptible by pressing ENTER.
# If interrupted, returns True.
def interruptible_sleep(t):
    rfds, _, _ = select.select([0], [], [], t)
    return 0 in rfds


def wait_for_string(s, timeout=TIMEOUT):
    logging.debug("Waiting for string: {}".format(s))
    deadline = time.time() + timeout
    while time.time() < deadline:
        output = capture_pane()
        if s in output:
            return
        if interruptible_sleep(1): return
    raise Exception("Timed out while waiting for {}!".format(s))


def wait_for_prompt():
    logging.debug("Waiting for prompt.")
    deadline = time.time() + TIMEOUT
    while time.time() < deadline:
        output = capture_pane()
        # If we are not at the bottom of the screen, there will be a bunch of extra \n's
        output = output.rstrip('\n')
        last_line = output.split('\n')[-1]
        # Our custom prompt on the VMs has two lines; the 2nd line is just '$'
        if last_line == "$":
            # This is a perfect opportunity to grab the node's IP address
            global IPADDR
            IPADDR = re.findall("\[(.*)\]", output, re.MULTILINE)[-1]
            return
        # When we are in an alpine container, the prompt will be "/ #"
        if last_line == "/ #":
            return
        # We did not recognize a known prompt; wait a bit and check again
        logging.debug("Could not find a known prompt on last line: {!r}"
                      .format(last_line))
        if interruptible_sleep(1): return
    raise Exception("Timed out while waiting for prompt!")


def check_exit_status():
    if not state.verify_status:
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
        logging.error("Couldn't connect to tmux. Please setup tmux first.")
        ipaddr = "$IPADDR"
        uid = os.getuid()

        raise Exception("""
1. If you're running this directly from a node:

tmux

2. If you want to control a remote tmux:

rm -f /tmp/tmux-{uid}/default && ssh -t -L /tmp/tmux-{uid}/default:/tmp/tmux-1001/default docker@{ipaddr} tmux new-session -As 0

(Or use workshopctl tmux)

3. If you cannot control a remote tmux:

tmux new-session ssh docker@{ipaddr}
""".format(uid=uid, ipaddr=ipaddr))
    else:
        logging.info("Found tmux session. Trying to acquire shell prompt.")
        wait_for_prompt()
    logging.info("Successfully connected to test cluster in tmux session.")


slides = [Slide("Dummy slide zero")]
content = open(sys.argv[1]).read()

# OK, this part is definitely hackish, and will break if the
# excludedClasses parameter is not on a single line.
excluded_classes = re.findall("excludedClasses: (\[.*\])", content)
excluded_classes = set(eval(excluded_classes[0]))

for slide in re.split("\n---?\n", content):
    slide_classes = re.findall("class: (.*)", slide)
    if slide_classes:
        slide_classes = slide_classes[0].split(",")
        slide_classes = [c.strip() for c in slide_classes]
    if excluded_classes & set(slide_classes):
        logging.debug("Skipping excluded slide.")
        continue
    slides.append(Slide(slide))


def capture_pane():
    return subprocess.check_output(["tmux", "capture-pane", "-p"]).decode('utf-8')


setup_tmux_and_ssh()


try:
    state.load()
    logging.debug("Successfully loaded state from file.")
    # Let's override the starting state, so that when an error occurs,
    # we can restart the auto-tester and then single-step or debug.
    # (Instead of running again through the same issue immediately.)
    state.interactive = True
except Exception as e:
    logging.exception("Could not load state from file.")
    logging.warning("Using default values.")


def move_forward():
    state.snippet += 1
    if state.snippet > len(slides[state.slide].snippets):
        state.slide += 1
        state.snippet = 0
    check_bounds()


def move_backward():
    state.snippet -= 1
    if state.snippet < 0:
        state.slide -= 1
        state.snippet = 0
    check_bounds()


def check_bounds():
    if state.slide < 1:
        state.slide = 1
    if state.slide >= len(slides):
        state.slide = len(slides)-1


##########################################################
# All functions starting with action_ correspond to the
# code to be executed when seeing ```foo``` blocks in the
# input. ```foo``` would call action_foo(state, snippet).
##########################################################


def send_keys(keys):
    subprocess.check_call(["tmux", "send-keys", keys])

# Send a single key.
# Useful for special keys, e.g. tmux interprets these strings:
# ^C (and all other sequences starting with a caret)
# Space
# ... and many others (check tmux manpage for details).
def action_key(state, snippet):
    send_keys(snippet.data)


# Send multiple keys.
# If keystroke simulation is off, all keys are sent at once.
# If keystroke simulation is on, keys are sent one by one, with a delay between them.
def action_keys(state, snippet, keys=None):
    if keys is None:
        keys = snippet.data
    if not state.simulate_type:
        send_keys(keys)
    else:
        for key in keys:
            if key == ";":
                key = "\\;"
            if key == "\n":
                if interruptible_sleep(1): return
            send_keys(key)
            if interruptible_sleep(0.15*random.random()): return
            if key == "\n":
                if interruptible_sleep(1): return


def action_hide(state, snippet):
    if state.run_hidden:
        action_bash(state, snippet)


def action_bash(state, snippet):
    data = snippet.data
    # Make sure that we're ready
    wait_for_prompt()
    # Strip leading spaces
    data = re.sub("\n +", "\n", data)
    # Remove backticks (they are used to highlight sections)
    data = data.replace('`', '')
    # Add "RETURN" at the end of the command :)
    data += "\n"
    # Send command
    action_keys(state, snippet, data)
    # Force a short sleep to avoid race condition
    time.sleep(0.5)
    if snippet.next and snippet.next.method == "wait":
        wait_for_string(snippet.next.data)
    elif snippet.next and snippet.next.method == "longwait":
        wait_for_string(snippet.next.data, 10*TIMEOUT)
    else:
        wait_for_prompt()
        # Verify return code
        check_exit_status()


def action_copy(state, snippet):
    screen = capture_pane()
    matches = re.findall(snippet.data, screen, flags=re.DOTALL)
    if len(matches) == 0:
        raise Exception("Could not find regex {} in output.".format(snippet.data))
    # Arbitrarily get the most recent match
    match = matches[-1]
    # Remove line breaks (like a screen copy paste would do)
    match = match.replace('\n', '')
    logging.debug("Copied {} to clipboard.".format(match))
    state.clipboard = match


def action_paste(state, snippet):
    logging.debug("Pasting {} from clipboard.".format(state.clipboard))
    action_keys(state, snippet, state.clipboard)


def action_check(state, snippet):
    wait_for_prompt()
    check_exit_status()


def action_open(state, snippet):
    # Cheap way to get node1's IP address
    screen = capture_pane()
    url = snippet.data.replace("/node1", "/{}".format(IPADDR))
    # This should probably be adapted to run on different OS
    if state.open_links:
        subprocess.check_output(["xdg-open", url])
        focus_browser()
        if state.interactive:
            print("Press any key to continue to next step...")
            click.getchar()


def action_tmux(state, snippet):
    subprocess.check_call(["tmux"] + snippet.data.split())


def action_unknown(state, snippet):
    logging.warning("Unknown method {}: {!r}".format(snippet.method, snippet.data))


def run_snippet(state, snippet):
    logging.info("Running with method {}: {}".format(snippet.method, snippet.data))
    try:
        action = globals()["action_"+snippet.method]
    except KeyError:
        action = action_unknown
    try:
        action(state, snippet)
        result = "OK"
    except:
        result = "ERR"
        logging.exception("While running method {} with {!r}".format(snippet.method, snippet.data))
        # Try to recover
        try:
            wait_for_prompt()
        except:
            subprocess.check_call(["tmux", "new-window"])
            wait_for_prompt()
    outfile.write("{} SLIDE={} METHOD={} DATA={!r}\n".format(result, state.slide, snippet.method, snippet.data))
    outfile.flush()


while True:
    state.save()
    slide = slides[state.slide]
    if state.snippet and state.snippet <= len(slide.snippets):
        snippet = slide.snippets[state.snippet-1]
    else:
        snippet = None
    click.clear()
    print("[Slide {}/{}] [Snippet {}/{}] [simulate_type:{}] [verify_status:{}] "
          "[switch_desktop:{}] [sync_slides:{}] [open_links:{}] [run_hidden:{}]"
          .format(state.slide, len(slides)-1,
                  state.snippet, len(slide.snippets) if slide.snippets else 0,
                  state.simulate_type, state.verify_status,
                  state.switch_desktop, state.sync_slides,
                  state.open_links, state.run_hidden))
    print(hrule())
    if snippet:
        print(slide.content.replace(snippet.content, ansi(7)(snippet.content)))
        focus_terminal()
    else:
        print(slide.content)
        if state.sync_slides:
            subprocess.check_output(["./gotoslide.js", str(slide.number)])
        focus_slides()
    print(hrule())
    if state.interactive:
        print("y/⎵/⏎   Execute snippet or advance to next snippet")
        print("p/←     Previous")
        print("n/→     Next")
        print("s       Simulate keystrokes")
        print("v       Validate exit status")
        print("d       Switch desktop")
        print("k       Sync slides")
        print("o       Open links")
        print("h       Run hidden commands")
        print("g       Go to a specific slide")
        print("q       Quit")
        print("c       Continue non-interactively until next error")
        command = click.getchar()
    else:
        command = "y"

    if command in ("n", "\x1b[C"):
        move_forward()
    elif command in ("p", "\x1b[D"):
        move_backward()
    elif command == "s":
        state.simulate_type = not state.simulate_type
    elif command == "v":
        state.verify_status = not state.verify_status
    elif command == "d":
        state.switch_desktop = not state.switch_desktop
    elif command == "k":
        state.sync_slides = not state.sync_slides
    elif command == "o":
        state.open_links = not state.open_links
    elif command == "h":
        state.run_hidden = not state.run_hidden
    elif command == "g":
        state.slide = click.prompt("Enter slide number", type=int)
        state.snippet = 0
        check_bounds()
    elif command == "q":
        break
    elif command == "c":
        # continue until next timeout
        state.interactive = False
    elif command in ("y", "\r", " "):
        if snippet:
            run_snippet(state, snippet)
            move_forward()
        else:
            # Advance to next snippet
            # Advance until a slide that has snippets
            while not slides[state.slide].snippets:
                move_forward()
                # But stop if we reach the last slide
                if state.slide == len(slides)-1:
                    break
            # And then advance to the snippet
            move_forward()
    else:
        logging.warning("Unknown command {}.".format(command))
