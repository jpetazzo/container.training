#!/usr/bin/env python2
# transforms a YAML manifest into a HTML workshop file

import glob
import logging
import os
import re
import string
import subprocess
import sys
import yaml


logging.basicConfig(level=os.environ.get("LOG_LEVEL", "INFO"))


def anchor(title):
    title = title.lower().replace(' ', '-')
    title = ''.join(c for c in title if c in string.ascii_letters+'-')
    return "toc-" + title


def interstitials_generator():
    images = [url.strip() for url in open("interstitials.txt") if url.strip()]
    while True:
        for image in images:
            yield image
interstitials = interstitials_generator()


def insertslide(markdown, title):
    title_position = markdown.find("\n# {}\n".format(title))
    slide_position = markdown.rfind("\n---\n", 0, title_position+1)
    logging.debug("Inserting title slide at position {}: {}".format(slide_position, title))

    before = markdown[:slide_position]

    toclink = "toc-chapter-{}".format(title2path[title][0])
    _titles_ = [""] + all_titles + [""]
    currentindex = _titles_.index(title)
    previouslink = anchor(_titles_[currentindex-1])
    nextlink = anchor(_titles_[currentindex+1])
    interstitial = interstitials.next()

    extra_slide = """
---

class: pic

.interstitial[![Image separating from the next chapter]({interstitial})]

---

name: {anchor}
class: title

{title}

.nav[
[Previous section](#{previouslink})
|
[Back to table of contents](#{toclink})
|
[Next section](#{nextlink})
]

.debug[(automatically generated title slide)]
""".format(anchor=anchor(title), interstitial=interstitial, title=title, toclink=toclink, previouslink=previouslink, nextlink=nextlink)
    after = markdown[slide_position:]
    return before + extra_slide + after


def flatten(titles):
    for title in titles:
        if isinstance(title, list):
            for t in flatten(title):
                yield t
        else:
            yield title


def generatefromyaml(manifest, filename):
    manifest = yaml.safe_load(manifest)

    markdown, titles = processchapter(manifest["chapters"], filename)
    logging.debug("Found {} titles.".format(len(titles)))
    toc = gentoc(titles)
    markdown = markdown.replace("@@TOC@@", toc)
    for title in flatten(titles):
        markdown = insertslide(markdown, title)

    exclude = manifest.get("exclude", [])
    logging.debug("exclude={!r}".format(exclude))
    if not exclude:
        logging.warning("'exclude' is empty.")
    exclude = ",".join('"{}"'.format(c) for c in exclude)

    # Insert build info. This is super hackish.

    markdown = markdown.replace(
        ".debug[",
        ".debug[\n```\n{}\n```\n\nThese slides have been built from commit: {}\n\n".format(dirtyfiles, commit),
        1)

    markdown = markdown.replace("@@TITLE@@", manifest["title"].replace("\n", "<br/>"))

    html = open("workshop.html").read()
    html = html.replace("@@MARKDOWN@@", markdown)
    html = html.replace("@@EXCLUDE@@", exclude)
    html = html.replace("@@CHAT@@", manifest["chat"])
    html = html.replace("@@GITREPO@@", manifest["gitrepo"])
    html = html.replace("@@SLIDES@@", manifest["slides"])
    html = html.replace("@@TITLE@@", manifest["title"].replace("\n", " "))
    html = html.replace("@@SLIDENUMBERPREFIX@@", manifest.get("slidenumberprefix", ""))
    return html


# Maps a section title (the string just after "^# ") to its position
# in the table of content (as a (chapter,part,subpart,...) tuple).
title2path = {}
path2title = {}
all_titles = []

# "tree" is a list of titles, potentially nested.
def gentoc(tree, path=()):
    if not tree:
        return ""
    if isinstance(tree, str):
        title = tree
        title2path[title] = path
        path2title[path] = title
        all_titles.append(title)
        logging.debug("Path {} Title {}".format(path, title))
        return "- [{}](#{})".format(title, anchor(title))
    if isinstance(tree, list):
        if len(path) == 0:
            return "\n---\n".join(gentoc(subtree, path+(i+1,)) for (i,subtree) in enumerate(tree))
        elif len(path) == 1:
            chapterslide = "name: toc-chapter-{n}\n\n## Chapter {n}\n\n".format(n=path[0])
            for (i,subtree) in enumerate(tree):
                chapterslide += gentoc(subtree, path+(i+1,)) + "\n\n"
            chapterslide += ".debug[(auto-generated TOC)]"
            return chapterslide
        else:
            return "\n\n".join(gentoc(subtree, path+(i+1,)) for (i,subtree) in enumerate(tree))


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
            slidefooter = ".debug[{}]".format(makelink(filename))
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
    logging.warning("Invalid chapter: {}".format(chapter))
    return "```\nInvalid chapter: {}\n```\n".format(chapter), []

# Try to figure out the URL of the repo on GitHub.
# This is used to generate "edit me on GitHub"-style links.
try:
    if "REPOSITORY_URL" in os.environ:
        repo = os.environ["REPOSITORY_URL"]
    else:
        repo = subprocess.check_output(["git", "config", "remote.origin.url"])
    repo = repo.strip().replace("git@github.com:", "https://github.com/")
    if "BRANCH" in os.environ:
        branch = os.environ["BRANCH"]
    else:
        branch = subprocess.check_output(["git", "rev-parse", "--abbrev-ref", "HEAD"])
        branch = branch.strip()
    base = subprocess.check_output(["git", "rev-parse", "--show-prefix"])
    base = base.strip().strip("/")
    urltemplate = ("{repo}/tree/{branch}/{base}/{filename}"
        .format(repo=repo, branch=branch, base=base, filename="{}"))
except:
    logging.exception("Could not generate repository URL; generating local URLs instead.")
    urltemplate = "file://{pwd}/{filename}".format(pwd=os.environ["PWD"], filename="{}")
try:
    commit = subprocess.check_output(["git", "rev-parse", "--short", "HEAD"])
except:
    logging.exception("Could not figure out HEAD commit.")
    commit = "??????"
try:
    dirtyfiles = subprocess.check_output(["git", "status", "--porcelain"])
except:
    logging.exception("Could not figure out repository cleanliness.")
    dirtyfiles = "?? git status --porcelain failed"

def makelink(filename):
    if os.path.isfile(filename):
        url = urltemplate.format(filename)
        return "[{}]({})".format(filename, url)
    else:
        return filename

if len(sys.argv) != 2:
    logging.error("This program takes one and only one argument: the YAML file to process.")
else:
    filename = sys.argv[1]
    if filename == "-":
        filename = "<stdin>"
        manifest = sys.stdin
    else:
        manifest = open(filename)
    logging.info("Processing {}...".format(filename))
    sys.stdout.write(generatefromyaml(manifest, filename))
    logging.info("Processed {}.".format(filename))
