#!/bin/sh
while true; do
  find . |
  entr -d . sh -c "DEBUG=1 ./markmaker.py < kube.yml > workshop.md"
done
