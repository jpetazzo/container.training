#!/bin/sh
#set -eu

if ! command -v http >/dev/null; then
  echo "Could not find the 'http' command line tool."
  echo "Please install it (the package name might be 'httpie')."
  exit 1
fi

. ~/creds/creds.cloudflare.dns

cloudflare() {
  case "$1" in
  GET|POST|DELETE)
    METHOD="$1"
    shift
    ;;
  *)
    METHOD=""
    ;;
  esac
  URI=$1
  shift
  http --ignore-stdin $METHOD https://api.cloudflare.com/client/v4/$URI "$@" "Authorization:Bearer $CLOUDFLARE_TOKEN"
}

_list_zones() {
  cloudflare zones | jq -r .result[].name
}

_get_zone_id() {
  cloudflare zones?name=$1 | jq -r .result[0].id
}

_populate_zone() {
  ZONE_ID=$(_get_zone_id $1)
  shift
  for IPADDR in $*; do
    cloudflare zones/$ZONE_ID/dns_records "name=*" "type=A" "content=$IPADDR"
    cloudflare zones/$ZONE_ID/dns_records "name=\@" "type=A" "content=$IPADDR"
  done
}

_clear_zone() {
  ZONE_ID=$(_get_zone_id $1)
  for RECORD_ID in $(
    cloudflare zones/$ZONE_ID/dns_records  | jq -r .result[].id
  ); do
    cloudflare DELETE zones/$ZONE_ID/dns_records/$RECORD_ID
  done
}

_add_zone() {
  cloudflare zones "name=$1"
}

echo "This script is still work in progress."
echo "You can source it and then use its individual functions."

