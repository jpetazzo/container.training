if ! command -v hcloud >/dev/null; then
  warning "Hetzner CLI (hcloud) not found."
fi
if ! [ -f ~/.config/hcloud/cli.toml ]; then
  warning "~/.config/hcloud/cli.toml not found."
fi

infra_list() {
    [ "$(hcloud server list -o json)" = "null" ] && return

    hcloud server list -o json |
        jq -r '.[] | [.id, .name , .status, .server_type.name] | @tsv'
}

infra_start() {
    COUNT=$1

    HETZNER_INSTANCE_TYPE=${HETZNER_INSTANCE_TYPE-cx21}
    HETZNER_DATACENTER=${HETZNER_DATACENTER-nbg1-dc3}
    HETZNER_IMAGE=${HETZNER_IMAGE-168855}

    for I in $(seq 1 $COUNT); do
        NAME=$(printf "%s-%03d" $TAG $I)
        sep "Starting instance $I/$COUNT"
        info "    Datacenter: $HETZNER_DATACENTER"
        info "          Name: $NAME"
        info " Instance type: $HETZNER_INSTANCE_TYPE"
        hcloud server create \
            --type=${HETZNER_INSTANCE_TYPE} \
            --datacenter=${HETZNER_DATACENTER} \
            --image=${HETZNER_IMAGE} \
            --name=$NAME \
            --label=tag=$TAG \
            --ssh-key ~/.ssh/id_rsa.pub
    done

    hetzner_get_ips_by_tag $TAG > tags/$TAG/ips.txt
}

infra_stop() {
    for ID in $(hetzner_get_ids_by_tag $TAG); do
        info "Scheduling deletion of instance $ID..."
        hcloud server delete $ID &
    done
    info "Waiting for deletion to complete..."
    wait
}

hetzner_get_ids_by_tag() {
    TAG=$1
    hcloud server list --selector=tag=$TAG -o json | jq -r .[].name
}

hetzner_get_ips_by_tag() {
    TAG=$1
    hcloud server list --selector=tag=$TAG -o json | jq -r .[].public_net.ipv4.ip
}
