if ! command -v scw >/dev/null; then
  warning "Scaleway CLI (scw) not found."
fi
if ! [ -f ~/.config/scw/config.yaml ]; then
  warning "~/.config/scw/config.yaml not found."
fi

SCW_INSTANCE_TYPE=${SCW_INSTANCE_TYPE-DEV1-M}
SCW_ZONE=${SCW_ZONE-fr-par-1}

infra_list() {
    scw instance server list -o json |
        jq -r '.[] | [.id, .name, .state, .commercial_type] | @tsv'
}

infra_start() {
    COUNT=$1

    for I in $(seq 1 $COUNT); do
        NAME=$(printf "%s-%03d" $TAG $I)
        sep "Starting instance $I/$COUNT"
        info "          Zone: $SCW_ZONE"
        info "          Name: $NAME"
        info " Instance type: $SCW_INSTANCE_TYPE"
        scw instance server create \
            type=${SCW_INSTANCE_TYPE} zone=${SCW_ZONE} \
            image=ubuntu_bionic name=${NAME}
    done
    sep

    scw_get_ips_by_tag $TAG > tags/$TAG/ips.txt
}

infra_stop() {
    info "Counting instances..."
    scw_get_ids_by_tag $TAG | wc -l
    info "Deleting instances..."
    scw_get_ids_by_tag $TAG | 
        xargs -n1 -P10 \
        scw instance server delete zone=${SCW_ZONE} force-shutdown=true with-ip=true
}

scw_get_ids_by_tag() {
    TAG=$1
    scw instance server list zone=${SCW_ZONE} name=$TAG -o json | jq -r .[].id
}

scw_get_ips_by_tag() {
    TAG=$1
    scw instance server list zone=${SCW_ZONE} name=$TAG -o json | jq -r .[].public_ip.address
}
