#!/usr/bin/env python
# transforms a YAML manifest into a MARKDOWN workshop file

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


def yaml2markdown(inf, outf):
    manifest = yaml.load(inf)
    markdown, titles = processchapter(manifest["chapters"])
    logging.debug(titles)
    toc = gentoc(titles)
    markdown = markdown.replace("@@TOC@@", toc)
    outf.write(markdown)


def gentoc(titles, depth=0, chapter=0):
    if not titles:
        return ""
    if type(titles) == str:
        return "  "*(depth-2) + "- " + titles + "\n"
    if type(titles) == list:
        if depth==0:
            sep = "\n\n---\n\n"
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


def findtitles(markdown):
    return re.findall("^# (.*)", markdown, re.MULTILINE)


# This takes a file name or a markdown snippet in argument.
# It returns (epxandedmarkdown,[list of titles])
# The list of titles can be nested.
def processchapter(chapter):
    if type(chapter) == str:
        if "\n" in chapter:
            return (chapter, findtitles(chapter))
        if os.path.isfile(chapter):
            return processchapter(open(chapter).read())
    if type(chapter) == list:
        chapters = [processchapter(c) for c in chapter]
        markdown = "\n---\n".join(c[0] for c in chapters)
        titles = [t for (m,t) in chapters if t]
        return (markdown, titles)
    raise InvalidChapter(chapter)



yaml2markdown(sys.stdin, sys.stdout)
