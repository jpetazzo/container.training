#!/usr/bin/env python3
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


class Interstitials(object):

    def __init__(self):
        self.index = 0
        self.images = [url.strip() for url in open("interstitials.txt") if url.strip()]

    def next(self):
        index = self.index % len(self.images)
        self.index += 1
        return self.images[index]


interstitials = Interstitials()


def insertslide(markdown, title):
    title_position = markdown.find("\n# {}\n".format(title))
    slide_position = markdown.rfind("\n---\n", 0, title_position+1)
    logging.debug("Inserting title slide at position {}: {}".format(slide_position, title))

    before = markdown[:slide_position]

    toclink = "toc-part-{}".format(title2part[title])
    _titles_ = [""] + all_titles + [""]
    currentindex = _titles_.index(title)
    previouslink = anchor(_titles_[currentindex-1])
    nextlink = anchor(_titles_[currentindex+1])
    interstitial = interstitials.next()

    extra_slide = """
---

class: pic

.interstitial[![Image separating from the next part]({interstitial})]

---

name: {anchor}
class: title

 {title}

.nav[
[Previous part](#{previouslink})
|
[Back to table of contents](#{toclink})
|
[Next part](#{nextlink})
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

    for k in manifest:
        override = os.environ.get("OVERRIDE_"+k)
        if override:
            manifest[k] = override

    for k in ["chat", "gitrepo", "slides", "title"]:
        if k not in manifest:
            manifest[k] = ""

    if "zip" not in manifest:
        if manifest["slides"].endswith('/'):
            manifest["zip"] = manifest["slides"] + "slides.zip"
        else:
            manifest["zip"] = manifest["slides"] + "/slides.zip"

    if "html" not in manifest:
        manifest["html"] = filename + ".html"

    markdown, titles = processcontent(manifest["content"], filename)
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
    html = html.replace("@@ZIP@@", manifest["zip"])
    html = html.replace("@@HTML@@", manifest["html"])
    html = html.replace("@@TITLE@@", manifest["title"].replace("\n", " "))
    html = html.replace("@@SLIDENUMBERPREFIX@@", manifest.get("slidenumberprefix", ""))

    # Process @@LINK[file] and @@INCLUDE[file] directives
    local_anchor_path = ".."
    # FIXME use dynamic repo and branch?
    online_anchor_path = "https://github.com/jpetazzo/container.training/tree/master"
    for atatlink in re.findall(r"@@LINK\[[^]]*\]", html):
        logging.debug("Processing {}".format(atatlink))
        file_name = atatlink[len("@@LINK["):-1]
        html = html.replace(atatlink, "[{}]({}/{})".format(file_name, online_anchor_path, file_name ))
    for atatinclude in re.findall(r"@@INCLUDE\[[^]]*\]", html):
        logging.debug("Processing {}".format(atatinclude))
        file_name = atatinclude[len("@@INCLUDE["):-1]
        file_path = os.path.join(local_anchor_path, file_name)
        html = html.replace(atatinclude, open(file_path).read())
    return html


# Maps a title (the string just after "^# ") to its position in the TOC
# (to which part it belongs).
title2part = {}
all_titles = []

# Generate the table of contents for a tree of titles.
# "tree" is a list of titles, potentially nested.
# Each entry is either:
# - a title (then it's a top-level section that doesn't show up in the TOC)
# - a list (then it's a part that will show up in the TOC on its own slide)
# In a list, we can have:
# - titles (simple entry)
# - further lists (they are then flattened; we don't represent subsubparts)
def gentoc(tree):
    # First, remove the top-level sections that don't show up in the TOC.
    tree = [ entry for entry in tree if type(entry)==list ]
    # Then, flatten the sublists.
    tree = [ list(flatten(entry)) for entry in tree ]
    # Now, process each part.
    parts = []
    for i, part in enumerate(tree):
        slide = "name: toc-part-{}\n\n".format(i+1)
        if len(tree) == 1:
            slide += "## Table of contents\n\n"
        else:
            slide += "## Part {}\n\n".format(i+1)
        for title in part:
            logging.debug("Generating TOC, part {}, title {}.".format(i+1, title))
            title2part[title] = i+1
            all_titles.append(title)
            slide += "- [{}](#{})\n".format(title, anchor(title))
            # If we don't have too many subparts, add some space to breathe.
            # (Otherwise, we display the titles smooched together.)
            if len(part) < 10:
                slide += "\n"
        slide += "\n.debug[(auto-generated TOC)]"
        parts.append(slide)
    return "\n---\n".join(parts)


# Arguments:
# - `content` is a string; if it has multiple lines, it will be used as
#   a markdown fragment; otherwise it will be considered as a file name
#   to be recursively loaded and parsed
# - `filename` is the name of the file that we're currently processing
#   (to generate inline comments to facilitate edition)
# Returns: (epxandedmarkdown,[list of titles])
# The list of titles can be nested.
def processcontent(content, filename):
    if isinstance(content, str):
        if "\n" in content:
            titles = re.findall("^# (.*)", content, re.MULTILINE)
            slidefooter = ".debug[{}]".format(makelink(filename))
            content = content.replace("\n---\n", "\n{}\n---\n".format(slidefooter))
            content += "\n" + slidefooter
            return (content, titles)
        if os.path.isfile(content):
            return processcontent(open(content).read(), content)
        logging.warning("Content spans only one line (it's probably a file name) but no file found: {}".format(content))
    if isinstance(content, list):
        subparts = [processcontent(c, filename) for c in content]
        markdown = "\n---\n".join(c[0] for c in subparts)
        titles = [t for (m,t) in subparts if t]
        return (markdown, titles)
    logging.warning("Invalid content: {}".format(content))
    return "```\nInvalid content: {}\n```\n".format(content), []

# Try to figure out the URL of the repo on GitHub.
# This is used to generate "edit me on GitHub"-style links.
try:
    if "REPOSITORY_URL" in os.environ:
        repo = os.environ["REPOSITORY_URL"]
    else:
        repo = subprocess.check_output(["git", "config", "remote.origin.url"]).decode("ascii")
    repo = repo.strip().replace("git@github.com:", "https://github.com/")
    if "BRANCH" in os.environ:
        branch = os.environ["BRANCH"]
    else:
        branch = subprocess.check_output(["git", "rev-parse", "--abbrev-ref", "HEAD"]).decode("ascii")
        branch = branch.strip()
    base = subprocess.check_output(["git", "rev-parse", "--show-prefix"]).decode("ascii")
    base = base.strip().strip("/")
    urltemplate = ("{repo}/tree/{branch}/{base}/{filename}"
        .format(repo=repo, branch=branch, base=base, filename="{}"))
except:
    logging.exception("Could not generate repository URL; generating local URLs instead.")
    urltemplate = "file://{pwd}/{filename}".format(pwd=os.environ["PWD"], filename="{}")
try:
    commit = subprocess.check_output(["git", "rev-parse", "--short", "HEAD"]).decode("ascii")
except:
    logging.exception("Could not figure out HEAD commit.")
    commit = "??????"
try:
    dirtyfiles = subprocess.check_output(["git", "status", "--porcelain"]).decode("ascii")
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
