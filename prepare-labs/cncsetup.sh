#!/bin/sh
if [ $(whoami) != ubuntu ]; then
  echo "This script should be executed on a freshly deployed node,"
  echo "with the 'ubuntu' user. Aborting."
  exit 1
fi
if id docker; then
  sudo userdel -r docker
fi
sudo apt-get update -q
sudo apt-get install -qy jq python-pip wkhtmltopdf xvfb
pip install --user awscli jinja2 pdfkit pssh
