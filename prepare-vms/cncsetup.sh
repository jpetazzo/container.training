#!/bin/sh
if [ $(whoami) != ubuntu ]; then
  echo "This script should be executed on a freshly deployed node,"
  echo "with the 'ubuntu' user. Aborting."
  exit 1
fi
if id docker; then
  sudo userdel -r docker
fi
pip install --user awscli jinja2 pdfkit
sudo apt-get install -y wkhtmltopdf xvfb
tmux new-session \; send-keys "
[ -f ~/.ssh/id_rsa ] || ssh-keygen

eval \$(ssh-agent)
ssh-add
Xvfb :0 &
export DISPLAY=:0
mkdir -p ~/www
sudo docker run -d -p 80:80 -v \$HOME/www:/usr/share/nginx/html nginx
"
