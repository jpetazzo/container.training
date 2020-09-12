if ! command -v aws >/dev/null; then
    warn "AWS CLI (aws) not found."
fi

infra_list() {
    aws_display_tags
}

infra_quotas() {
    aws_greet

    max_instances=$(aws ec2 describe-account-attributes \
        --attribute-names max-instances \
        --query 'AccountAttributes[*][AttributeValues]')
    info "In the current region ($AWS_DEFAULT_REGION) you can deploy up to $max_instances instances."

    # Print list of AWS EC2 regions, highlighting ours ($AWS_DEFAULT_REGION) in the list
    # If our $AWS_DEFAULT_REGION is not valid, the error message will be pretty descriptive:
    # Could not connect to the endpoint URL: "https://ec2.foo.amazonaws.com/"
    info "Available regions:"
    aws ec2 describe-regions | awk '{print $3}' | grep --color=auto $AWS_DEFAULT_REGION -C50
}

infra_start() {
    COUNT=$1

    # Print our AWS username, to ease the pain of credential-juggling
    aws_greet

    # Upload our SSH keys to AWS if needed, to be added to each VM's authorized_keys
    key_name=$(aws_sync_keys)

    AMI=$(aws_get_ami)    # Retrieve the AWS image ID
    if [ -z "$AMI" ]; then
        die "I could not find which AMI to use in this region. Try another region?"
    fi
    AWS_KEY_NAME=$(make_key_name)
    AWS_INSTANCE_TYPE=${AWS_INSTANCE_TYPE-t3a.medium}

    sep "Starting instances"
    info "         Count: $COUNT"
    info "        Region: $AWS_DEFAULT_REGION"
    info "     Token/tag: $TAG"
    info "           AMI: $AMI"
    info "      Key name: $AWS_KEY_NAME"
    info " Instance type: $AWS_INSTANCE_TYPE"
    result=$(aws ec2 run-instances \
        --key-name $AWS_KEY_NAME \
        --count $COUNT \
        --instance-type $AWS_INSTANCE_TYPE \
        --client-token $TAG \
        --block-device-mapping 'DeviceName=/dev/sda1,Ebs={VolumeSize=20}' \
        --image-id $AMI)
    reservation_id=$(echo "$result" | head -1 | awk '{print $2}')
    info "Reservation ID: $reservation_id"
    sep

    # if instance creation succeeded, we should have some IDs
    IDS=$(aws_get_instance_ids_by_client_token $TAG)
    if [ -z "$IDS" ]; then
        die "Instance creation failed."
    fi

    # Tag these new instances with a tag that is the same as the token
    aws_tag_instances $TAG $TAG

    # Wait until EC2 API tells us that the instances are running
    aws_wait_until_tag_is_running $TAG $COUNT

    aws_get_instance_ips_by_tag $TAG > tags/$TAG/ips.txt
}

infra_stop() {
    aws_kill_instances_by_tag
}

infra_opensg() {
    aws ec2 authorize-security-group-ingress \
        --group-name default \
        --protocol icmp \
        --port -1 \
        --cidr 0.0.0.0/0

    aws ec2 authorize-security-group-ingress \
        --group-name default \
        --protocol udp \
        --port 0-65535 \
        --cidr 0.0.0.0/0

    aws ec2 authorize-security-group-ingress \
        --group-name default \
        --protocol tcp \
        --port 0-65535 \
        --cidr 0.0.0.0/0
}

infra_disableaddrchecks() {
    IDS=$(aws_get_instance_ids_by_tag $TAG)
    for ID in $IDS; do
        info "Disabling source/destination IP checks on: $ID"
        aws ec2 modify-instance-attribute --source-dest-check "{\"Value\": false}" --instance-id $ID
    done
}

aws_wait_until_tag_is_running() {
    max_retry=100
    i=0
    done_count=0
    while [[ $done_count -lt $COUNT ]]; do
        let "i += 1"
        info "$(printf "%d/%d instances online" $done_count $COUNT)"
        done_count=$(aws ec2 describe-instances \
            --filters "Name=tag:Name,Values=$TAG" \
            "Name=instance-state-name,Values=running" \
            --query "length(Reservations[].Instances[])")
        if [[ $i -gt $max_retry ]]; then
            die "Timed out while waiting for instance creation (after $max_retry retries)"
        fi
        sleep 1
    done
}

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
    IDS=$(aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=$TAG" \
        --query "Reservations[*].Instances[*].InstanceId" | tr '\t' ' ')

    aws ec2 describe-instance-status \
        --instance-ids $IDS \
        --query "InstanceStatuses[*].{ID:InstanceId,InstanceState:InstanceState.Name,InstanceStatus:InstanceStatus.Status,SystemStatus:SystemStatus.Status,Reachability:InstanceStatus.Status}" \
        --output table
}

aws_display_instances_by_tag() {
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
    aws_get_instance_ids_by_filter Name=client-token,Values=$TOKEN
}

aws_get_instance_ids_by_tag() {
    aws_get_instance_ids_by_filter Name=tag:Name,Values=$TAG
}

aws_get_instance_ips_by_tag() {
    aws ec2 describe-instances --filter "Name=tag:Name,Values=$TAG" \
        --output text \
        --query "Reservations[*].Instances[*].PublicIpAddress" \
        | tr "\t" "\n" \
        | sort -n -t . -k 1,1 -k 2,2 -k 3,3 -k 4,4 # sort IPs
}

aws_kill_instances_by_tag() {
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

aws_get_ami() {
    ##VERSION##
    find_ubuntu_ami -r $AWS_DEFAULT_REGION -a amd64 -v 18.04 -t hvm:ebs -N -q
}

aws_greet() {
    IAMUSER=$(aws iam get-user --query 'User.UserName')
    info "Hello! You seem to be UNIX user $USER, and IAM user $IAMUSER."
}

aws_sync_keys() {
    # make sure ssh-add -l contains "RSA"
    ssh-add -l | grep -q RSA \
        || die "The output of \`ssh-add -l\` doesn't contain 'RSA'. Start the agent, add your keys?"

    AWS_KEY_NAME=$(make_key_name)
    info "Syncing keys... "
    if ! aws ec2 describe-key-pairs --key-name "$AWS_KEY_NAME" &>/dev/null; then
        aws ec2 import-key-pair --key-name $AWS_KEY_NAME \
            --public-key-material "$(ssh-add -L \
                | grep -i RSA \
                | head -n1 \
                | cut -d " " -f 1-2)" &>/dev/null

        if ! aws ec2 describe-key-pairs --key-name "$AWS_KEY_NAME" &>/dev/null; then
            die "Somehow, importing the key didn't work. Make sure that 'ssh-add -l | grep RSA | head -n1' returns an RSA key?"
        else
            info "Imported new key $AWS_KEY_NAME."
        fi
    else
        info "Using existing key $AWS_KEY_NAME."
    fi
}
