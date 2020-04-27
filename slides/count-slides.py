#!/usr/bin/env python
import re
import sys

PREFIX = "name: toc-"
EXCLUDED = ["in-person"]

class State(object):
    def __init__(self):
        self.current_slide = 1
        self.section_title = None
        self.section_start = 0
        self.section_slides = 0
        self.modules = {}
        self.sections = {}
    def show(self):
        if self.section_title.startswith("module-"):
            return
        print("{0.section_title}\t{0.section_start}\t{0.section_slides}".format(self))
        self.sections[self.section_title] = self.section_slides

state = State()

title = None
for line in open(sys.argv[1]):
    line = line.rstrip()
    if line.startswith(PREFIX):
        if state.section_title is None:
            print("{}\t{}\t{}".format("title", "index", "size"))
        else:
            state.show()
        state.section_title = line[len(PREFIX):].strip()
        state.section_start = state.current_slide
        state.section_slides = 0
    if line == "---":
        state.current_slide += 1
        state.section_slides += 1
    if line == "--":
        state.current_slide += 1
    toc_links = re.findall("\(#toc-(.*)\)", line)
    if toc_links and state.section_title.startswith("module-"):
        if state.section_title not in state.modules:
            state.modules[state.section_title] = []
        state.modules[state.section_title].append(toc_links[0])
    # This is really hackish
    if line.startswith("class:"):
        for klass in EXCLUDED:
            if klass in line:
                state.section_slides -= 1
                state.current_slide -= 1

state.show()

for module in sorted(state.modules, key=lambda f: int(f.split("-")[1])):
    module_size = sum(state.sections[s] for s in state.modules[module])
    print("{}\t{}\t{}".format("total size for", module, module_size))

