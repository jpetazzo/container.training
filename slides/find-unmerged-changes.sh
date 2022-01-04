#!/bin/sh

# The materials for a given training live in their own branch.
# Sometimes, we write custom content (or simply new content) for a training,
# and that content doesn't get merged back to main. This script tries to
# detect that with the following heuristics:
# - list all remote branches
# - for each remote branch, list the changes that weren't merged into main
#   (using "diff main...$BRANCH", three dots)
# - ignore a bunch of training-specific files that change all the time anyway
# - for the remaining files, compute the diff between main and the branch
#   (using "diff main..$BRANCH", two dots)
# - ignore changes of less than 10 lines
# - also ignore a few red herrings
# - display whatever is left

# For "git diff" (in the filter function) to work correctly, we must be
# at the root of the repo.
cd $(git rev-parse --show-toplevel)

BRANCHES=$(git branch -r | grep -v origin/HEAD | grep origin/2)

filter() {
  threshold=10
  while read filename; do
    case $filename in
      # Generic training-specific files
      slides/*.html) continue;;
      slides/*.yml) continue;;
      slides/logistics*.md) continue;;
      # Specific content that can be ignored
      #slides/containers/Local_Environment.md) threshold=100;;
      # Content that was moved/refactored enough to confuse us
      slides/containers/Local_Environment.md) threshold=100;;
      slides/exercises.md) continue;;
      slides/k8s/batch-jobs) threshold=20;;
      # Renames
      */{*}*) continue;;
    esac
    git diff --find-renames --numstat main..$BRANCH -- "$filename" | {
      # If the files are identical, the diff will be empty, and "read" will fail.
      read plus minus filename || return
      # Ignore binary files (FIXME though?)
      if [ $plus = - ]; then
        return
      fi
      diff=$((plus-minus))
      if [ $diff -gt $threshold ]; then
        echo git diff main..$BRANCH -- $filename
      fi
    }
  done
}

for BRANCH in $BRANCHES; do
  if FILES=$(git diff --find-renames --name-only main...$BRANCH | filter | grep .); then
    echo "🌳 $BRANCH:"
    echo "$FILES"
  fi
done
