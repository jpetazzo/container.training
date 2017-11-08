#!/bin/sh
if ! [ -f "$1" ]; then
  echo "File $1 not found, aborting."
  exit 1
fi
if [ -f "$2" ]; then
  echo "File $2 already exists, aborting."
  exit 1
fi
git mv "$1" "$2"
sed -i "" "s,$1,$2," */*.md
