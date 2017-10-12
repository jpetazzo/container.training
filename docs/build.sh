#!/bin/sh

for YAML in *.yml; do
  ./markmaker.py < $YAML > $YAML.html || rm $YAML.html
done

if [ "$1" = "watch" ]; then
  while true; do
    find . | entr -d $0 && break
  done
fi
