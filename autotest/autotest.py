#!/usr/bin/env python

import os
import re
import subprocess
import sys

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
content = open(sys.argv[1]).read()
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
        elif highlight == "keys":
            print("K "+content)
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

try:
    i = int(open("nextstep").read())
except Exception as e:
    print("Could not read nextstep file ({}), initializing to 0.".format(e))
    i = 0

while True:
    with open("nextstep","w") as f:
        f.write(str(i))
    typ, cmd = actions[i]
    print_snippet(cmd)
    print("i={} shall we execute the snippet above with {}?".format(i, typ))
    command = raw_input()
    if command == "":
        if typ in ["bash", "keys"]:
            if typ=="keys" and cmd=="^C":
                print("^C detected")
                cmd="\x03"
            subprocess.check_call(["tmux", "send-keys", "{}\n".format(cmd)])
        else:
            print "DO NOT KNOW HOW TO HANDLE", typ, cmd
        i += 1
    elif command.isdigit():
        i = int(command)
    else:
        i += 1
        # skip other "commands"
