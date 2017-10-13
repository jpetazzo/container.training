#!/bin/sh
case "$1" in
once)
  for YAML in *.yml; do
    ./markmaker.py < $YAML > $YAML.html || rm $YAML.html
  done
  ;;

forever)
  # There is a weird bug in entr, at least on MacOS,
  # where it doesn't restore the terminal to a clean
  # state when exitting. So let's try to work around
  # it with stty.
  STTY=$(stty -g)
  while true; do
    find . | entr -d $0 once
    [ $? = 2 ] || break
  done
  stty $STTY
  ;;

*)
  echo "$0 <once|forever>"
  ;;
esac
