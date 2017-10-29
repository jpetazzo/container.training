aws_display_tags() {
    # Print all "Name" tags in our region with their instance count
    echo "[#] [Status] [Token] [Tag]" \
        | awk '{ printf "%-7s %-12s %-25s %-25s\n", $1, $2, $3, $4}'
    aws ec2 describe-instances \
        --query "Reservations[*].Instances[*].[State.Name,ClientToken,Tags[0].Value]" \
        | tr -d "\r" \
        | uniq -c \
        | sort -k 3 \
        | awk '{ printf "%-7s %-12s %-25s %-25s\n", $1, $2, $3, $4}'
}

aws_get_tokens() {
    aws ec2 describe-instances --output text \
        --query 'Reservations[*].Instances[*].[ClientToken]' \
        | sort -u
}

aws_display_instance_statuses_by_tag() {
    TAG=$1
    need_tag $TAG

    IDS=$(aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=$TAG" \
        --query "Reservations[*].Instances[*].InstanceId" | tr '\t' ' ')

    aws ec2 describe-instance-status \
        --instance-ids $IDS \
        --query "InstanceStatuses[*].{ID:InstanceId,InstanceState:InstanceState.Name,InstanceStatus:InstanceStatus.Status,SystemStatus:SystemStatus.Status,Reachability:InstanceStatus.Status}" \
        --output table
}

aws_display_instances_by_tag() {
    TAG=$1
    need_tag $TAG
    result=$(aws ec2 describe-instances --output table \
        --filter "Name=tag:Name,Values=$TAG" \
        --query "Reservations[*].Instances[*].[ \
                        InstanceId, \
                        State.Name, \
                        Tags[0].Value, \
                        PublicIpAddress, \
                        InstanceType \
                        ]"
    )
    if [[ -z $result ]]; then
        die "No instances found with tag $TAG in region $AWS_DEFAULT_REGION."
    else
        echo "$result"
    fi
}

aws_get_instance_ids_by_filter() {
    FILTER=$1
    aws ec2 describe-instances --filters $FILTER \
        --query Reservations[*].Instances[*].InstanceId \
        --output text | tr "\t" "\n" | tr -d "\r"
}

aws_get_instance_ids_by_client_token() {
    TOKEN=$1
    need_tag $TOKEN
    aws_get_instance_ids_by_filter Name=client-token,Values=$TOKEN
}

aws_get_instance_ids_by_tag() {
    TAG=$1
    need_tag $TAG
    aws_get_instance_ids_by_filter Name=tag:Name,Values=$TAG
}

aws_get_instance_ips_by_tag() {
    TAG=$1
    need_tag $TAG
    aws ec2 describe-instances --filter "Name=tag:Name,Values=$TAG" \
        --output text \
        --query "Reservations[*].Instances[*].PublicIpAddress" \
        | tr "\t" "\n" \
        | sort -n -t . -k 1,1 -k 2,2 -k 3,3 -k 4,4 # sort IPs
}

aws_kill_instances_by_tag() {
    TAG=$1
    need_tag $TAG
    IDS=$(aws_get_instance_ids_by_tag $TAG)
    if [ -z "$IDS" ]; then
        die "Invalid tag."
    fi

    info "Deleting instances with tag $TAG."

    aws ec2 terminate-instances --instance-ids $IDS \
        | grep ^TERMINATINGINSTANCES

    info "Deleted instances with tag $TAG."
}

aws_tag_instances() {
    OLD_TAG_OR_TOKEN=$1
    NEW_TAG=$2
    IDS=$(aws_get_instance_ids_by_client_token $OLD_TAG_OR_TOKEN)
    [[ -n "$IDS" ]] && aws ec2 create-tags --tag Key=Name,Value=$NEW_TAG --resources $IDS >/dev/null
    IDS=$(aws_get_instance_ids_by_tag $OLD_TAG_OR_TOKEN)
    [[ -n "$IDS" ]] && aws ec2 create-tags --tag Key=Name,Value=$NEW_TAG --resources $IDS >/dev/null
}
