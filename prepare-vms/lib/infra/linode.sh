if ! command -v linode-cli >/dev/null; then
  warning "Linode CLI (linode-cli) not found."
fi
if ! [ -f ~/.config/linode-cli ]; then
  warning "~/.config/linode-cli not found."
fi

# To view available regions: "linode-cli regions list"
LINODE_REGION=${LINODE_REGION-us-west}

# To view available types: "linode-cli linodes types"
LINODE_TYPE=${LINODE_TYPE-g6-standard-2}

infra_list() {
    linode-cli linodes list --json |
        jq -r '.[] | [.id, .label, .status, .type] | @tsv'
}

infra_start() {
    COUNT=$1

    for I in $(seq 1 $COUNT); do
        NAME=$(printf "%s-%03d" $TAG $I)
        sep "Starting instance $I/$COUNT"
        info "          Zone: $LINODE_REGION"
        info "          Name: $NAME"
        info " Instance type: $LINODE_TYPE"
        ROOT_PASS="$(base64 /dev/urandom | cut -c1-20 | head -n 1)"
        MAX_TRY=5
        TRY=1
        WAIT=1
        while ! linode-cli linodes create \
            --type=${LINODE_TYPE} --region=${LINODE_REGION} \
            --image=linode/ubuntu18.04 \
            --authorized_keys="${LINODE_SSHKEY}" \
            --root_pass="${ROOT_PASS}" \
            --tags=${TAG} --label=${NAME}; do
              warning "Failed to create VM (attempt $TRY/$MAX_TRY)."
              if [ $TRY -ge $MAX_TRY ]; then
                  die "Giving up."
              fi
              info "Waiting $WAIT seconds and retrying."
              sleep $WAIT
              TRY=$(($TRY+1))
              WAIT=$(($WAIT*2))
            done
    done
    sep

    linode_get_ips_by_tag $TAG > tags/$TAG/ips.txt
}

infra_stop() {
    info "Counting instances..."
    linode_get_ids_by_tag $TAG | wc -l
    info "Deleting instances..."
    linode_get_ids_by_tag $TAG | 
        xargs -n1 -P10 \
        linode-cli linodes delete
}

linode_get_ids_by_tag() {
    TAG=$1
    linode-cli linodes list --tags $TAG --json | jq -r ".[].id"
}

linode_get_ips_by_tag() {
    TAG=$1
    linode-cli linodes list --tags $TAG --json | jq -r ".[].ipv4[0]"
}
