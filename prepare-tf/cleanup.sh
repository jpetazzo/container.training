#!/bin/sh
for T in  tag-*; do
(
  cd $T
  terraform apply -destroy -auto-approve && mv ../$T ../deleted$T
)
done
