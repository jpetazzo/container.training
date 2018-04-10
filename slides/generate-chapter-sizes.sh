#!/bin/sh
INPUT=$1

{
  echo "# Front matter"
  cat "$INPUT"
} | 
  grep -e "^# " -e ^---$ | uniq -c | 
  sed "s/^ *//" | sed s/---// | 
  paste -d "\t" - - 
