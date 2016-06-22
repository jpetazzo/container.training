#!/usr/bin/env python
"""
Extract and print level 1 and 2 titles from workshop slides.
"""

with open("htdocs/index.html", "r") as f:
    data = f.read()

# @jpetazzo abuses "class: title" to make a point sometimes
skip = [
    "Why?",
    "---",
    "But ...",
    "WHY?!?",
]

# Ditch linebreaks from main section titles
replace = [
    "<br/>",
]

# remove blank lines
sections = [x for x in data.split('\n') if x] # and x not in skip]
sections = "\n".join(sections)
sections = sections.split('class: title')
del(sections[0]) # delete the CSS frontmatter

for section in sections:
    lines = [x for x in section.split("\n") if x]

    if lines[0] not in skip:
        title = lines[0]
        title = title.replace("<br/> ", "")
        title = title.replace("# ", "")
        del(lines[0])
        print("{}".format(title))

    titles = [x[2:] for x in lines if x.startswith("# ")]
    for title in titles:
        print("\t{}".format(title))
