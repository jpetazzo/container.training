#!/usr/bin/env python

import os
import re
import sys

html_file = sys.argv[1]
output_file_template = "_academy_{}.html"
title_regex = "name: toc-(.*)"
redirects = open("_redirects", "w")

sections = re.split(title_regex, open(html_file).read())[1:]

while sections:
    link, markdown = sections[0], sections[1]
    sections = sections[2:]
    output_file_name = output_file_template.format(link)
    with open(output_file_name, "w") as f:
        html = open("workshop.html").read()
        html = html.replace("@@MARKDOWN@@", markdown)
        titles = re.findall("# (.*)", markdown) + [""]
        html = html.replace("@@TITLE@@", "{} — Kubernetes Academy".format(titles[0]))
        html = html.replace("@@SLIDENUMBERPREFIX@@", "")
        html = html.replace("@@EXCLUDE@@", "")
        html = html.replace(".nav[", ".hide[")
        f.write(html)
    redirects.write("/{} /{} 200!\n".format(link, output_file_name))

html = open(html_file).read()
html = re.sub("#toc-([^)]*)", "_academy_\\1.html", html)
sys.stdout.write(html)
