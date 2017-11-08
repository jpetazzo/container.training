#!/usr/bin/env python
"""
Extract and print level 1 and 2 titles from workshop slides.
"""

separators = [
    "---",
    "--"
]

slide_count = 1
for line in open("index.html"):
    line = line.strip()
    if line in separators:
        slide_count += 1
    if line.startswith('#  '):
        print slide_count, '# #', line
    elif line.startswith('# '):
        print slide_count, line
