infra_list() {
    die "unimplemented"
}

infra_quotas() {
    die "unimplemented"
}

infra_start() {
    COUNT=$1

    AWS_KEY_NAME=$(make_key_name)
    SCW_INSTANCE_TYPE=${SCW_INSTANCE_TYPE-DEV1-M}
    SCW_ZONE=${SCW_ZONE-fr-par-1}

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
    for ID in $(scw_get_ids_by_tag $TAG); do
        info "Scheduling deletion of instance $ID..."
        scw instance server delete force-shutdown=true server-id=$ID &
    done
    info "Waiting for deletion to complete..."
    wait
}

scw_get_ids_by_tag() {
    TAG=$1
    scw instance server list name=$TAG -o json | jq -r .[].id
}

scw_get_ips_by_tag() {
    TAG=$1
    scw instance server list name=$TAG -o json | jq -r .[].public_ip.address
}

infra_opensg() {
    die "unimplemented"
}

infra_disableaddrchecks() {
    die "unimplemented"
}
