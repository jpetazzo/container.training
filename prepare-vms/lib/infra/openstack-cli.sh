infra_list() {
    openstack server list -f json |
        jq -r '.[] | [.ID, .Name , .Status, .Flavor] | @tsv'
}

infra_start() {
    COUNT=$1

    sep "Starting $COUNT instances"
    info " Region: $OS_REGION_NAME"
    info "   User: $OS_USERNAME"
    info " Flavor: $OS_FLAVOR"
    info "  Image: $OS_IMAGE"
    openstack server create \
    	--flavor $OS_FLAVOR \
    	--image $OS_IMAGE \
    	--key-name $OS_KEY \
    	--min $COUNT --max $COUNT \
    	--property workshopctl=$TAG \
    	$TAG

    sep "Waiting for IP addresses to be available"
    GOT=0
    while [ "$GOT" != "$COUNT" ]; do
    	echo "Got $GOT/$COUNT IP addresses."
    	oscli_get_ips_by_tag $TAG > tags/$TAG/ips.txt
    	GOT="$(wc -l < tags/$TAG/ips.txt)"
    done

}

infra_stop() {
	info "Counting instances..."
	oscli_get_instances_json $TAG | 
		jq -r .[].Name | 
		wc -l
	info "Deleting instances..."
	oscli_get_instances_json $TAG |
		jq -r .[].Name |
		xargs -P10 -n1 openstack server delete
	info "Done."
}

oscli_get_instances_json() {
	TAG=$1
    openstack server list -f json --name "${TAG}-[0-9]*"
}

oscli_get_ips_by_tag() {
    TAG=$1
    oscli_get_instances_json $TAG |
    	jq -r .[].Networks | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' || true
}
