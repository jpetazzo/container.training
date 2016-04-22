#!/usr/bin/env python

import os
import re
import signal
import subprocess
import time

def print_snippet(snippet):
    print(78*'-')
    print(snippet)
    print(78*'-')

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
            if "```" in exercise and "<br/>`" in exercise:
                print("! Exercise on slide {} has both ``` and <br/>` delimiters, skipping."
                      .format(self.number))
                print_snippet(exercise)
            elif "```" in exercise:
                for snippet in exercise.split("```")[1::2]:
                    self.snippets.append(Snippet(self, snippet))
            elif "<br/>`" in exercise:
                for snippet in re.findall("<br/>`(.*)`", exercise):
                    self.snippets.append(Snippet(self, snippet))
            else:
                print("  Exercise on slide {} has neither ``` or <br/>` delimiters, skipping."
                     .format(self.number))

    def __str__(self):
        text = self.content
        for snippet in self.snippets:
            text = text.replace(snippet.content, ansi("7")(snippet.content))
        return text


def ansi(code):
    return lambda s: "\x1b[{}m{}\x1b[0m".format(code, s)

slides = []
with open("index.html") as f:
    content = f.read()
    for slide in re.split("\n---?\n", content):
        slides.append(Slide(slide))

is_editing_file = False
placeholders = {}
for slide in slides:
    for snippet in slide.snippets:
        content = snippet.content
        # Multi-line snippets should be ```highlightsyntax...
        # Single-line snippets will be interpreted as shell commands
        if '\n' in content:
            highlight, content = content.split('\n', 1)
        else:
            highlight = "bash"
        content = content.strip()
        # If the previous snippet was a file fragment, and the current
        # snippet is not YAML or EDIT, complain.
        if is_editing_file and highlight not in ["yaml", "edit"]:
            print("! On slide {}, previous snippet was YAML, so what do what do?"
                  .format(slide.number))
            print_snippet(content)
        is_editing_file = False
        if highlight == "yaml":
            is_editing_file = True
        elif highlight == "placeholder":
            for line in content.split('\n'):
                variable, value = line.split(' ', 1)
                placeholders[variable] = value
        elif highlight == "bash":
            for variable, value in placeholders.items():
                quoted = "`{}`".format(variable)
                if quoted in content:
                    content = content.replace(quoted, value)
                    del placeholders[variable]
            if '`' in content:
                print("! The following snippet on slide {} contains a backtick:"
                      .format(slide.number))
                print_snippet(content)
                continue
            print("_ "+content)
            snippet.actions.append((highlight, content))
        elif highlight == "edit":
            print(". "+content)
            snippet.actions.append((highlight, content))
        elif highlight == "meta":
            print("^ "+content)
            snippet.actions.append((highlight, content))
        else:
            print("! Unknown highlight {!r} on slide {}.".format(highlight, slide.number))
if placeholders:
    print("! Remaining placeholder values: {}".format(placeholders))

actions = sum([snippet.actions for snippet in sum([slide.snippets for slide in slides], [])], [])

# Strip ^{ ... ^} for now
def strip_curly_braces(actions, in_braces=False):
    if actions == []:
        return []
    elif actions[0] == ("meta", "^{"):
        return strip_curly_braces(actions[1:], True)
    elif actions[0] == ("meta", "^}"):
        return strip_curly_braces(actions[1:], False)
    elif in_braces:
        return strip_curly_braces(actions[1:], True)
    else:
        return [actions[0]] + strip_curly_braces(actions[1:], False)

actions = strip_curly_braces(actions)

background = []
cwd = os.path.expanduser("~")
env = {}
for current_action, next_action in zip(actions, actions[1:]+[("bash", "true")]):
    if current_action[0] == "meta":
        continue
    print(ansi(7)(">>> {}".format(current_action[1])))
    time.sleep(1)
    popen_options = dict(shell=True, cwd=cwd, stdin=subprocess.PIPE, preexec_fn=os.setpgrp)
    # The follow hack allows to capture the environment variables set by `docker-machine env`
    # FIXME: this doesn't handle `unset` for now
    if any([
        "eval $(docker-machine env" in current_action[1],
        "DOCKER_HOST" in current_action[1],
        "COMPOSE_FILE" in current_action[1],
        ]):
        popen_options["stdout"] = subprocess.PIPE
        current_action[1] += "\nenv"
    proc = subprocess.Popen(current_action[1], **popen_options)
    proc.cmd = current_action[1]
    if next_action[0] == "meta":
        print(">>> {}".format(next_action[1]))
        time.sleep(3)
        if next_action[1] == "^C":
            os.killpg(proc.pid, signal.SIGINT)
            proc.wait()
        elif next_action[1] == "^Z":
            # Let the process run
            background.append(proc)
        elif next_action[1] == "^D":
            proc.communicate()
            proc.wait()
        else:
            print("! Unknown meta action {} after snippet:".format(next_action[1]))
            print_snippet(next_action[1])
        print(ansi(7)("<<< {}".format(current_action[1])))
    else:
        proc.wait()
        if "stdout" in popen_options:
            stdout, stderr = proc.communicate()
            for line in stdout.split('\n'):
                if line.startswith("DOCKER_"):
                    variable, value = line.split('=', 1)
                    env[variable] = value
                    print("=== {}={}".format(variable, value))
        print(ansi(7)("<<< {} >>> {}".format(proc.returncode, current_action[1])))
        if proc.returncode != 0:
            print("Got non-zero status code; aborting.")
            break
    if current_action[1].startswith("cd "):
        cwd = os.path.expanduser(current_action[1][3:])
for proc in background:
    print("Terminating background process:")
    print_snippet(proc.cmd)
    proc.terminate()
    proc.wait()

