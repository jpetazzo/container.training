#!/usr/bin/env python
import re
import sys
import yaml

FIRST_SLIDE_MARKER = "name: toc-"
PART_PREFIX = "part-"

filename = sys.argv[1]
if filename.endswith(".html"):
    html_file = filename
    yaml_file = filename[: -len(".html")]
else:
    html_file = filename + ".html"
    yaml_file = filename
excluded_classes = yaml.safe_load(open(yaml_file))["exclude"]


class State(object):
    def __init__(self):
        self.current_slide = -1
        self.parts = {}

    def end_section(self):
        if state.section_title:
            print(
                "{0.section_start}\t{0.section_slides}\t{0.section_title}".format(self)
            )
        if self.section_part:
            if self.section_part not in self.parts:
                self.parts[self.section_part] = 0
            self.parts[self.section_part] += self.section_slides

    def new_section(self, slide):
        # Normally, the title should be prefixed by a space
        # (because section titles are first-level titles in markdown,
        # e.g. "# Introduction", and markmaker removes the # but leaves
        # the leading space).
        self.section_title = None
        if "\n " in slide:
            self.section_title = slide.split("\n ")[1].split("\n")[0]
        toc_links = re.findall("\(#toc-(.*)\)", slide)
        self.section_part = None
        for toc_link in toc_links:
            if toc_link.startswith(PART_PREFIX):
                self.section_part = toc_link
        self.section_start = self.current_slide
        self.section_slides = 0


state = State()
state.new_section("")
print("{}\t{}\t{}".format("index", "size", "title"))

for slide in open(html_file).read().split("\n---\n"):
    excluded = False
    for line in slide.split("\n"):
        if line.startswith("class:"):
            for klass in excluded_classes:
                if klass in line.split():
                    excluded = True
    if excluded:
        continue
    if FIRST_SLIDE_MARKER in slide:
        # A new section starts. Show info about the part that just ended.
        state.end_section()
        state.new_section(slide)
    state.section_slides += 1
    for sub_slide in slide.split("\n--\n"):
        state.current_slide += 1
else:
    state.end_section()

for part in sorted(state.parts, key=lambda f: int(f.split("-")[1])):
    print("{}\t{}\t{}".format(0, state.parts[part], "total size for " + part))
