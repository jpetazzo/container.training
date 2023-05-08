#!/bin/sh

# https://open-api.netlify.com/#tag/dnsZone
[ "$1" ] || {
  echo ""
  echo "Add a record in Netlify DNS."
  echo "This script is hardcoded to add a record to container.training".
  echo ""
  echo "Syntax:"
  echo "$0 list"
  echo "$0 add <name> <ipaddr>"
  echo "$0 del <recordid>"
  echo ""
  echo "Example to create a A record for eu.container.training:"
  echo "$0 add eu 185.145.250.0"
  echo ""
  exit 1
}

NETLIFY_CONFIG_FILE=~/.config/netlify/config.json
if ! [ "$DOMAIN" ]; then
  DOMAIN=container.training
fi

if ! [ -f "$NETLIFY_CONFIG_FILE" ]; then
  echo "Could not find Netlify configuration file ($NETLIFY_CONFIG_FILE)."
  echo "Try to run the following command, and try again:"
  echo "npx netlify-cli login"
  exit 1
fi

if ! command -v http >/dev/null; then
  echo "Could not find the 'http' command line tool."
  echo "Please install it (the package name might be 'httpie')."
  exit 1
fi

NETLIFY_USERID=$(jq .userId < "$NETLIFY_CONFIG_FILE")
NETLIFY_TOKEN=$(jq -r .users[$NETLIFY_USERID].auth.token < "$NETLIFY_CONFIG_FILE")

netlify() {
  URI=$1
  shift
  http https://api.netlify.com/api/v1/$URI "$@" "Authorization:Bearer $NETLIFY_TOKEN"
}

ZONE_ID=$(netlify dns_zones |
          jq -r '.[] | select ( .name == "'$DOMAIN'" ) | .id')

_list() {
  netlify dns_zones/$ZONE_ID/dns_records |
    jq -r '.[] | select(.type=="A") | [.hostname, .type, .value, .id] | @tsv'
}

_add() {
  NAME=$1.$DOMAIN
  ADDR=$2


  # It looks like if we create two identical records, then delete one of them,
  # Netlify DNS ends up in a weird state (the name doesn't resolve anymore even
  # though it's still visible through the API and the website?)

  if netlify dns_zones/$ZONE_ID/dns_records |
          jq '.[] | select(.hostname=="'$NAME'" and .type=="A" and .value=="'$ADDR'")' |
          grep .
  then
    echo "It looks like that record already exists. Refusing to create it."
    exit 1
  fi

  netlify dns_zones/$ZONE_ID/dns_records type=A hostname=$NAME value=$ADDR ttl=300

  netlify dns_zones/$ZONE_ID/dns_records |
          jq '.[] | select(.hostname=="'$NAME'")'
}

_del() {
  RECORD_ID=$1
  # OK, since that one is dangerous, I'm putting the whole request explicitly here
  http DELETE \
    https://api.netlify.com/api/v1/dns_zones/$ZONE_ID/dns_records/$RECORD_ID \
    "Authorization:Bearer $NETLIFY_TOKEN"
}

case "$1" in
  list)
    _list
    ;;
  add)
    _add $2 $3
    ;;
  del)
    _del $2
    ;;
  *)
    echo "Unknown command '$1'."
    exit 1
    ;;
esac
