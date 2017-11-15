#!/bin/sh
grep --color=auto -P -n "[^\x00-\x80]" */*.md
