#!/bin/sh

DOMAINS=~/Dropbox/domains.txt
IPS=ips.txt

. ./dns-cloudflare.sh

paste "$DOMAINS" "$IPS" | while read domain ips; do
  if ! [ "$domain" ]; then
    echo "⚠️ No more domains!"
    exit 1
  fi
  _clear_zone "$domain"
  _populate_zone "$domain" $ips
done
echo "✅ All done."
