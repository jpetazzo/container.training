#!/bin/sh
for LINK in $(cat */*.md | sed -n 's/^\[\(.*\)\]:.*/\1/p' | sort | uniq -d); do
  grep '^\['"$LINK"'\]:' */*.md
done

