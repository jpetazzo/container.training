#!/usr/bin/env python
# transforms a YAML manifest into a HTML workshop file

import glob
import logging
import os
import re
import sys  
import yaml


if os.environ.get("DEBUG") == "1":
    logging.basicConfig(level=logging.DEBUG)


class InvalidChapter(ValueError):

    def __init__(self, chapter):
        ValueError.__init__(self, "Invalid chapter: {!r}".format(chapter))


def generatefromyaml(manifest):
    manifest = yaml.load(manifest)

    markdown, titles = processchapter(manifest["chapters"], "<inline>")
    logging.debug(titles)
    toc = gentoc(titles)
    markdown = markdown.replace("@@TOC@@", toc)
    for (s1,s2) in manifest.get("variables", {}).items():
        markdown = markdown.replace(s1, s2)

    exclude = manifest.get("exclude", [])
    logging.debug("exclude={!r}".format(exclude))
    if not exclude:
        logging.warning("'exclude' is empty.")
    exclude = ",".join('"{}"'.format(c) for c in exclude)

    html = open("workshop.html").read()
    html = html.replace("@@MARKDOWN@@", markdown)
    html = html.replace("@@EXCLUDE@@", exclude)
    return html


def gentoc(titles, depth=0, chapter=0):
    if not titles:
        return ""
    if isinstance(titles, str):
        return "  "*(depth-2) + "- " + titles + "\n"
    if isinstance(titles, list):
        if depth==0:
            sep = "\n\n<!-- auto-generated TOC -->\n---\n\n"
            head = ""
            tail = ""
        elif depth==1:
            sep = "\n"
            head = "## Chapter {}\n\n".format(chapter)
            tail = ""
        else:
            sep = "\n"
            head = ""
            tail = ""
        return head + sep.join(gentoc(t, depth+1, c+1) for (c,t) in enumerate(titles)) + tail


# Arguments:
# - `chapter` is a string; if it has multiple lines, it will be used as
#   a markdown fragment; otherwise it will be considered as a file name
#   to be recursively loaded and parsed
# - `filename` is the name of the file that we're currently processing
#   (to generate inline comments to facilitate edition)
# Returns: (epxandedmarkdown,[list of titles])
# The list of titles can be nested.
def processchapter(chapter, filename):
    if isinstance(chapter, unicode):
        return processchapter(chapter.encode("utf-8"), filename)
    if isinstance(chapter, str):
        if "\n" in chapter:
            titles = re.findall("^# (.*)", chapter, re.MULTILINE)
            slidefooter = "<!-- {} -->".format(filename)
            chapter = chapter.replace("\n---\n", "\n{}\n---\n".format(slidefooter))
            chapter += "\n" + slidefooter
            return (chapter, titles)
        if os.path.isfile(chapter):
            return processchapter(open(chapter).read(), chapter)
    if isinstance(chapter, list):
        chapters = [processchapter(c, filename) for c in chapter]
        markdown = "\n---\n".join(c[0] for c in chapters)
        titles = [t for (m,t) in chapters if t]
        return (markdown, titles)
    raise InvalidChapter(chapter)


sys.stdout.write(generatefromyaml(sys.stdin))
