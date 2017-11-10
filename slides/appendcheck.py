#!/usr/bin/env python

import logging
import os
import subprocess
import sys

logging.basicConfig(level=os.environ.get("LOG_LEVEL", "INFO"))

filename = sys.argv[1]

logging.info("Checking file {}...".format(filename))
text = subprocess.check_output(["./slidechecker.js", filename])
html = open(filename).read()
html = html.replace("</textarea>", "\n---\n```\n{}\n```\n</textarea>".format(text))

open(filename, "w").write(html)
