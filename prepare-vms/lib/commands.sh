export AWS_DEFAULT_OUTPUT=text

HELP=""
_cmd() {
    HELP="$(printf "%s\n%-12s %s\n" "$HELP" "$1" "$2")"
}

_cmd help "Show available commands"
_cmd_help() {
    printf "$(basename $0) - the orchestration workshop swiss army knife\n"
    printf "Commands:"
    printf "%s" "$HELP" | sort
}

_cmd amis "List Ubuntu AMIs in the current region"
_cmd_amis() {
    find_ubuntu_ami -r $AWS_DEFAULT_REGION "$@"
}

_cmd ami "Show the AMI that will be used for deployment"
_cmd_ami() {
    find_ubuntu_ami -r $AWS_DEFAULT_REGION -a amd64 -v 16.04 -t hvm:ebs -N -q
}

_cmd build "Build the Docker image to run this program in a container"
_cmd_build() {
    docker-compose build
}

_cmd wrap "Run this program in a container"
_cmd_wrap() {
    docker-compose run --rm workshopctl "$@"
}

_cmd cards "Generate ready-to-print cards for a batch of VMs"
_cmd_cards() {
    TAG=$1
    SETTINGS=$2
    need_tag $TAG
    need_settings $SETTINGS

    aws_get_instance_ips_by_tag $TAG >tags/$TAG/ips.txt

    # Remove symlinks to old cards
    rm -f ips.html ips.pdf

    # This will generate two files in the base dir: ips.pdf and ips.html
    python lib/ips-txt-to-html.py $SETTINGS

    for f in ips.html ips.pdf; do
        # Remove old versions of cards if they exist
        rm -f tags/$TAG/$f

        # Move the generated file and replace it with a symlink
        mv -f $f tags/$TAG/$f && ln -s tags/$TAG/$f $f
    done

    info "Cards created. You can view them with:"
    info "xdg-open ips.html ips.pdf (on Linux)"
    info "open ips.html ips.pdf (on MacOS)"
}

_cmd deploy "Install Docker on a bunch of running VMs"
_cmd_deploy() {
    TAG=$1
    SETTINGS=$2
    need_tag $TAG
    need_settings $SETTINGS
    link_tag $TAG
    count=$(wc -l ips.txt)

    # wait until all hosts are reachable before trying to deploy
    info "Trying to reach $TAG instances..."
    while ! tag_is_reachable $TAG; do
        >/dev/stderr echo -n "."
        sleep 2
    done
    >/dev/stderr echo ""

    sep "Deploying tag $TAG"
    pssh -I tee /tmp/settings.yaml <$SETTINGS
    pssh "
    sudo apt-get update &&
    sudo apt-get install -y python-setuptools &&
    sudo easy_install pyyaml"

    # Copy postprep.py to the remote machines, and execute it, feeding it the list of IP addresses
    pssh -I tee /tmp/postprep.py <lib/postprep.py
    pssh --timeout 900 --send-input "python /tmp/postprep.py >>/tmp/pp.out 2>>/tmp/pp.err" <ips.txt

    # Install docker-prompt script
    pssh -I sudo tee /usr/local/bin/docker-prompt <lib/docker-prompt
    pssh sudo chmod +x /usr/local/bin/docker-prompt

    # If /home/docker/.ssh/id_rsa doesn't exist, copy it from node1
    pssh "
    sudo -u docker [ -f /home/docker/.ssh/id_rsa ] ||
    ssh -o StrictHostKeyChecking=no node1 sudo -u docker tar -C /home/docker -cvf- .ssh |
    sudo -u docker tar -C /home/docker -xf-"

    # if 'docker@' doesn't appear in /home/docker/.ssh/authorized_keys, copy it there
    pssh "
    grep docker@ /home/docker/.ssh/authorized_keys ||
    cat /home/docker/.ssh/id_rsa.pub |
    sudo -u docker tee -a /home/docker/.ssh/authorized_keys"

    # On node1, create and deploy TLS certs using Docker Machine
    # (Currently disabled.)
    true || pssh "
    if grep -q node1 /tmp/node; then
        grep ' node' /etc/hosts | 
        xargs -n2 sudo -H -u docker \
        docker-machine create -d generic --generic-ssh-user docker --generic-ip-address
    fi"

    sep "Deployed tag $TAG"
    info "You may want to run one of the following commands:"
    info "$0 kube $TAG"
    info "$0 pull_images $TAG"
    info "$0 cards $TAG $SETTINGS"
}

_cmd kube "Setup kubernetes clusters with kubeadm (must be run AFTER deploy)"
_cmd_kube() {

    # Install packages
    pssh "
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg |
    sudo apt-key add - &&
    echo deb http://apt.kubernetes.io/ kubernetes-xenial main |
    sudo tee /etc/apt/sources.list.d/kubernetes.list"
    pssh "
    sudo apt-get update -q &&
    sudo apt-get install -qy kubelet kubeadm kubectl
    kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl"

    # Work around https://github.com/kubernetes/kubernetes/issues/53356
    pssh "
    if [ ! -f /etc/kubernetes/kubelet.conf ]; then
        sudo systemctl stop kubelet
        sudo rm -rf /var/lib/kubelet/pki
    fi"

    # Initialize kube master
    pssh "
    if grep -q node1 /tmp/node && [ ! -f /etc/kubernetes/admin.conf ]; then
        sudo kubeadm init
    fi"

    # Put kubeconfig in ubuntu's and docker's accounts
    pssh "
    if grep -q node1 /tmp/node; then
        sudo mkdir -p \$HOME/.kube /home/docker/.kube &&
        sudo cp /etc/kubernetes/admin.conf \$HOME/.kube/config &&
        sudo cp /etc/kubernetes/admin.conf /home/docker/.kube/config &&
        sudo chown -R \$(id -u) \$HOME/.kube &&
        sudo chown -R docker /home/docker/.kube
    fi"

    # Get bootstrap token
    pssh "
    if grep -q node1 /tmp/node; then
        TOKEN_NAME=\$(kubectl -n kube-system get secret -o name | grep bootstrap-token)
        TOKEN_ID=\$(kubectl -n kube-system get \$TOKEN_NAME -o go-template --template '{{ index .data \"token-id\" }}' | base64 -d)
        TOKEN_SECRET=\$(kubectl -n kube-system get \$TOKEN_NAME -o go-template --template '{{ index .data \"token-secret\" }}' | base64 -d)
        echo \$TOKEN_ID.\$TOKEN_SECRET >/tmp/token
    fi"

    # Install weave as the pod network
    pssh "
    if grep -q node1 /tmp/node; then
        kubever=\$(kubectl version | base64 | tr -d '\n')
        kubectl apply -f https://cloud.weave.works/k8s/net?k8s-version=\$kubever
    fi"

    # Join the other nodes to the cluster
    pssh "
    if ! grep -q node1 /tmp/node && [ ! -f /etc/kubernetes/kubelet.conf ]; then
        TOKEN=\$(ssh -o StrictHostKeyChecking=no node1 cat /tmp/token)
        sudo kubeadm join --token \$TOKEN node1:6443
    fi"

    sep "Done"
}

_cmd ids "List the instance IDs belonging to a given tag or token"
_cmd_ids() {
    TAG=$1
    need_tag $TAG

    info "Looking up by tag:"
    aws_get_instance_ids_by_tag $TAG

    # Just in case we managed to create instances but weren't able to tag them
    info "Looking up by token:"
    aws_get_instance_ids_by_client_token $TAG
}

_cmd ips "List the IP addresses of the VMs for a given tag or token"
_cmd_ips() {
    TAG=$1
    need_tag $TAG
    mkdir -p tags/$TAG
    aws_get_instance_ips_by_tag $TAG | tee tags/$TAG/ips.txt
    link_tag $TAG
}

_cmd list "List available batches in the current region"
_cmd_list() {
    info "Listing batches in region $AWS_DEFAULT_REGION:"
    aws_display_tags
}

_cmd status "List instance status for a given batch"
_cmd_status() {
    info "Using region $AWS_DEFAULT_REGION."
    TAG=$1
    need_tag $TAG
    describe_tag $TAG
    tag_is_reachable $TAG
    info "You may be interested in running one of the following commands:"
    info "$0 ips $TAG"
    info "$0 deploy $TAG <settings/somefile.yaml>"
}

_cmd opensg "Open the default security group to ALL ingress traffic"
_cmd_opensg() {
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

_cmd pull_images "Pre-pull a bunch of Docker images"
_cmd_pull_images() {
    TAG=$1
    need_tag $TAG
    pull_tag $TAG
}

_cmd retag "Apply a new tag to a batch of VMs"
_cmd_retag() {
    OLDTAG=$1
    NEWTAG=$2
    need_tag $OLDTAG
    if [[ -z "$NEWTAG" ]]; then
        die "You must specify a new tag to apply."
    fi
    aws_tag_instances $OLDTAG $NEWTAG
}

_cmd start "Start a batch of VMs"
_cmd_start() {
    # Number of instances to create
    COUNT=$1
    # Optional settings file (to carry on with deployment)
    SETTINGS=$2

    if [ -z "$COUNT" ]; then
        die "Indicate number of instances to start."
    fi

    # Print our AWS username, to ease the pain of credential-juggling
    greet

    # Upload our SSH keys to AWS if needed, to be added to each VM's authorized_keys
    key_name=$(sync_keys)

    AMI=$(_cmd_ami)    # Retrieve the AWS image ID
    TOKEN=$(get_token) # generate a timestamp token for this batch of VMs
    AWS_KEY_NAME=$(make_key_name)

    sep "Starting instances"
    info "         Count: $COUNT"
    info "        Region: $AWS_DEFAULT_REGION"
    info "     Token/tag: $TOKEN"
    info "           AMI: $AMI"
    info "      Key name: $AWS_KEY_NAME"
    result=$(aws ec2 run-instances \
        --key-name $AWS_KEY_NAME \
        --count $COUNT \
        --instance-type t2.medium \
        --client-token $TOKEN \
        --image-id $AMI)
    reservation_id=$(echo "$result" | head -1 | awk '{print $2}')
    info "Reservation ID: $reservation_id"
    sep

    # if instance creation succeeded, we should have some IDs
    IDS=$(aws_get_instance_ids_by_client_token $TOKEN)
    if [ -z "$IDS" ]; then
        die "Instance creation failed."
    fi

    # Tag these new instances with a tag that is the same as the token
    TAG=$TOKEN
    aws_tag_instances $TOKEN $TAG

    wait_until_tag_is_running $TAG $COUNT

    sep
    info "Successfully created $COUNT instances with tag $TAG"
    sep

    mkdir -p tags/$TAG
    IPS=$(aws_get_instance_ips_by_tag $TAG)
    echo "$IPS" >tags/$TAG/ips.txt
    link_tag $TAG
    if [ -n "$SETTINGS" ]; then
        _cmd_deploy $TAG $SETTINGS
    else
        info "To deploy or kill these instances, run one of the following:"
        info "$0 deploy $TAG <settings/somefile.yaml>"
        info "$0 stop $TAG"
    fi
}

_cmd ec2quotas "Check our EC2 quotas (max instances)"
_cmd_ec2quotas() {
    greet

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

_cmd stop "Stop (terminate, shutdown, kill, remove, destroy...) instances"
_cmd_stop() {
    TAG=$1
    need_tag $TAG
    aws_kill_instances_by_tag $TAG
}

_cmd test "Run tests (pre-flight checks) on a batch of VMs"
_cmd_test() {
    TAG=$1
    need_tag $TAG
    test_tag $TAG
}

###

greet() {
    IAMUSER=$(aws iam get-user --query 'User.UserName')
    info "Hello! You seem to be UNIX user $USER, and IAM user $IAMUSER."
}

link_tag() {
    TAG=$1
    need_tag $TAG
    IPS_FILE=tags/$TAG/ips.txt
    need_ips_file $IPS_FILE
    ln -sf $IPS_FILE ips.txt
}

pull_tag() {
    TAG=$1
    need_tag $TAG
    link_tag $TAG
    if [ ! -s $IPS_FILE ]; then
        die "Nonexistent or empty IPs file $IPS_FILE."
    fi

    # Pre-pull a bunch of images
    pssh --timeout 900 'for I in \
            debian:latest \
            ubuntu:latest \
            fedora:latest \
            centos:latest \
            postgres \
            redis \
            training/namer \
            nathanleclaire/redisonrails; do
        sudo -u docker docker pull $I
    done'

    info "Finished pulling images for $TAG."
    info "You may now want to run:"
    info "$0 cards $TAG <settings/somefile.yaml>"
}

wait_until_tag_is_running() {
    max_retry=50
    TAG=$1
    COUNT=$2
    i=0
    done_count=0
    while [[ $done_count -lt $COUNT ]]; do
        let "i += 1"
        info "$(printf "%d/%d instances online" $done_count $COUNT)"
        done_count=$(aws ec2 describe-instances \
            --filters "Name=instance-state-name,Values=running" \
            "Name=tag:Name,Values=$TAG" \
            --query "Reservations[*].Instances[*].State.Name" \
            | tr "\t" "\n" \
            | wc -l)

        if [[ $i -gt $max_retry ]]; then
            die "Timed out while waiting for instance creation (after $max_retry retries)"
        fi
        sleep 1
    done
}

tag_is_reachable() {
    TAG=$1
    need_tag $TAG
    link_tag $TAG
    pssh -t 5 true 2>&1 >/dev/null
}

test_tag() {
    ips_file=tags/$TAG/ips.txt
    info "Picking a random IP address in $ips_file to run tests."
    n=$((1 + $RANDOM % $(wc -l <$ips_file)))
    ip=$(head -n $n $ips_file | tail -n 1)
    test_vm $ip
    info "Tests complete."
}

test_vm() {
    ip=$1
    info "Testing instance with IP address $ip."
    user=ubuntu
    errors=""

    for cmd in "hostname" \
        "whoami" \
        "hostname -i" \
        "cat /tmp/node" \
        "cat /tmp/ipv4" \
        "cat /etc/hosts" \
        "hostnamectl status" \
        "docker version | grep Version -B1" \
        "docker-compose version" \
        "docker-machine version" \
        "docker images" \
        "docker ps" \
        "curl --silent localhost:55555" \
        "sudo ls -la /mnt/ | grep docker" \
        "env" \
        "ls -la /home/docker/.ssh"; do
        sep "$cmd"
        echo "$cmd" \
            | ssh -A -q \
                -o "UserKnownHostsFile /dev/null" \
                -o "StrictHostKeyChecking=no" \
                $user@$ip sudo -u docker -i \
            || {
                status=$?
                error "$cmd exit status: $status"
                errors="[$status] $cmd\n$errors"
            }
    done
    sep
    if [ -n "$errors" ]; then
        error "The following commands had non-zero exit codes:"
        printf "$errors"
    fi
    info "Test VM was $ip."
}

make_key_name() {
    SHORT_FINGERPRINT=$(ssh-add -l | grep RSA | head -n1 | cut -d " " -f 2 | tr -d : | cut -c 1-8)
    echo "${SHORT_FINGERPRINT}-${USER}"
}

sync_keys() {
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

get_token() {
    if [ -z $USER ]; then
        export USER=anonymous
    fi
    date +%Y-%m-%d-%H-%M-$USER
}

describe_tag() {
    # Display instance details and reachability/status information
    TAG=$1
    need_tag $TAG
    aws_display_instances_by_tag $TAG
    aws_display_instance_statuses_by_tag $TAG
}
