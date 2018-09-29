export AWS_DEFAULT_OUTPUT=text

HELP=""
_cmd() {
    HELP="$(printf "%s\n%-12s %s\n" "$HELP" "$1" "$2")"
}

_cmd help "Show available commands"
_cmd_help() {
    printf "$(basename $0) - the container training swiss army knife\n"
    printf "Commands:"
    printf "%s" "$HELP" | sort
}

_cmd build "Build the Docker image to run this program in a container"
_cmd_build() {
    docker-compose build
}

_cmd wrap "Run this program in a container"
_cmd_wrap() {
    docker-compose run --rm workshopctl "$@"
}

_cmd cards "Generate ready-to-print cards for a group of VMs"
_cmd_cards() {
    TAG=$1
    need_tag

    # This will process ips.txt to generate two files: ips.pdf and ips.html
    (
        cd tags/$TAG
        ../../lib/ips-txt-to-html.py settings.yaml
    )

    info "Cards created. You can view them with:"
    info "xdg-open tags/$TAG/ips.html tags/$TAG/ips.pdf (on Linux)"
    info "open tags/$TAG/ips.html (on macOS)"
}

_cmd deploy "Install Docker on a bunch of running VMs"
_cmd_deploy() {
    TAG=$1
    need_tag

    # wait until all hosts are reachable before trying to deploy
    info "Trying to reach $TAG instances..."
    while ! tag_is_reachable; do
        >/dev/stderr echo -n "."
        sleep 2
    done
    >/dev/stderr echo ""

    echo deploying > tags/$TAG/status
    sep "Deploying tag $TAG"
    pssh -I tee /tmp/settings.yaml <tags/$TAG/settings.yaml
    pssh "
    sudo apt-get update &&
    sudo apt-get install -y python-setuptools &&
    sudo easy_install pyyaml"

    # Copy postprep.py to the remote machines, and execute it, feeding it the list of IP addresses
    pssh -I tee /tmp/postprep.py <lib/postprep.py
    pssh --timeout 900 --send-input "python /tmp/postprep.py >>/tmp/pp.out 2>>/tmp/pp.err" <tags/$TAG/ips.txt

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
    echo deployed > tags/$TAG/status
    info "You may want to run one of the following commands:"
    info "$0 kube $TAG"
    info "$0 pull_images $TAG"
    info "$0 cards $TAG"
}

_cmd kube "Setup kubernetes clusters with kubeadm (must be run AFTER deploy)"
_cmd_kube() {
    TAG=$1
    need_tag

    # Install packages
    pssh --timeout 200 "
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg |
    sudo apt-key add - &&
    echo deb http://apt.kubernetes.io/ kubernetes-xenial main |
    sudo tee /etc/apt/sources.list.d/kubernetes.list"
    pssh --timeout 200 "
    sudo apt-get update -q &&
    sudo apt-get install -qy kubelet kubeadm kubectl &&
    kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl"

    # Initialize kube master
    pssh --timeout 200 "
    sudo kubeadm reset -f
    if grep -q node1 /tmp/node && [ ! -f /etc/kubernetes/admin.conf ]; then
        kubeadm token generate > /tmp/token &&
	sudo kubeadm init --token \$(cat /tmp/token)
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

    # Install weave as the pod network
    pssh "
    if grep -q node1 /tmp/node; then
        kubever=\$(kubectl version | base64 | tr -d '\n') &&
        kubectl apply -f https://cloud.weave.works/k8s/net?k8s-version=\$kubever
    fi"

    # Join the other nodes to the cluster
    pssh --timeout 200 "
    if ! grep -q node1 /tmp/node && [ ! -f /etc/kubernetes/kubelet.conf ]; then
        TOKEN=\$(ssh -o StrictHostKeyChecking=no node1 cat /tmp/token) &&
        sudo kubeadm join --discovery-token-unsafe-skip-ca-verification --token \$TOKEN node1:6443
    fi"

    # Install kubectx and kubens
    pssh "
    [ -d kubectx ] || git clone https://github.com/ahmetb/kubectx &&
    sudo ln -sf /home/ubuntu/kubectx/kubectx /usr/local/bin/kctx &&
    sudo ln -sf /home/ubuntu/kubectx/kubens /usr/local/bin/kns &&
    sudo cp /home/ubuntu/kubectx/completion/*.bash /etc/bash_completion.d &&
    [ -d kube-ps1 ] || git clone https://github.com/jonmosco/kube-ps1 &&
    sudo -u docker sed -i s/docker-prompt/kube_ps1/ /home/docker/.bashrc &&
    sudo -u docker tee -a /home/docker/.bashrc <<EOF
. /home/ubuntu/kube-ps1/kube-ps1.sh
KUBE_PS1_PREFIX=""
KUBE_PS1_SUFFIX=""
KUBE_PS1_SYMBOL_ENABLE="false"
KUBE_PS1_CTX_COLOR="green"
KUBE_PS1_NS_COLOR="green"
EOF"

    # Install stern
    pssh "
    if [ ! -x /usr/local/bin/stern ]; then
        sudo curl -L -o /usr/local/bin/stern https://github.com/wercker/stern/releases/download/1.8.0/stern_linux_amd64 &&
        sudo chmod +x /usr/local/bin/stern &&
        stern --completion bash | sudo tee /etc/bash_completion.d/stern
    fi"

    # Install helm
    pssh "
    if [ ! -x /usr/local/bin/helm ]; then
        curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | sudo bash &&
        helm completion bash | sudo tee /etc/bash_completion.d/helm
    fi"

    sep "Done"
}

_cmd kubetest "Check that all nodes are reporting as Ready"
_cmd_kubetest() {
    TAG=$1
    need_tag

    # There are way too many backslashes in the command below.
    # Feel free to make that better ♥
    pssh "
    set -e
    [ -f /tmp/node ]
    if grep -q node1 /tmp/node; then
      which kubectl
      for NODE in \$(awk /\ node/\ {print\ \\\$2} /etc/hosts); do
        echo \$NODE ; kubectl get nodes | grep -w \$NODE | grep -w Ready
      done
    fi"
}

_cmd ids "(FIXME) List the instance IDs belonging to a given tag or token"
_cmd_ids() {
    TAG=$1
    need_tag $TAG

    info "Looking up by tag:"
    aws_get_instance_ids_by_tag $TAG

    # Just in case we managed to create instances but weren't able to tag them
    info "Looking up by token:"
    aws_get_instance_ids_by_client_token $TAG
}

_cmd list "List available groups for a given infrastructure"
_cmd_list() {
    need_infra $1
    infra_list
}

_cmd listall "List VMs running on all configured infrastructures"
_cmd_listall() {
    for infra in infra/*; do
        case $infra in
        infra/example.*)
            ;;
        *)
            info "Listing infrastructure $infra:"
            need_infra $infra
            infra_list
            ;;
        esac
    done
}

_cmd netfix "Disable GRO and run a pinger job on the VMs"
_cmd_netfix () {
    TAG=$1
    need_tag

    pssh "
    sudo ethtool -K ens3 gro off
    sudo tee /root/pinger.service <<EOF
[Unit]
Description=pinger

[Install]
WantedBy=multi-user.target

[Service]
WorkingDirectory=/
ExecStart=/bin/ping -w60 1.1
User=nobody
Group=nogroup
Restart=always
EOF
    sudo systemctl enable /root/pinger.service
    sudo systemctl start pinger"
}

_cmd opensg "Open the default security group to ALL ingress traffic"
_cmd_opensg() {
    need_infra $1
    infra_opensg
}

_cmd pull_images "Pre-pull a bunch of Docker images"
_cmd_pull_images() {
    TAG=$1
    need_tag
    pull_tag
}

_cmd quotas "Check our infrastructure quotas (max instances)"
_cmd_quotas() {
    need_infra $1
    infra_quotas
}

_cmd retag "(FIXME) Apply a new tag to a group of VMs"
_cmd_retag() {
    OLDTAG=$1
    NEWTAG=$2
    TAG=$OLDTAG
    need_tag
    if [[ -z "$NEWTAG" ]]; then
        die "You must specify a new tag to apply."
    fi
    aws_tag_instances $OLDTAG $NEWTAG
}

_cmd start "Start a group of VMs"
_cmd_start() {
    while [ ! -z "$*" ]; do
        case "$1" in
        --infra) INFRA=$2; shift 2;;
        --settings) SETTINGS=$2; shift 2;;
        --count) COUNT=$2; shift 2;;
        --tag) TAG=$2; shift 2;;
        *) die "Unrecognized parameter: $1."
        esac
    done
    
    if [ -z "$INFRA" ]; then
        die "Please add --infra flag to specify which infrastructure file to use."
    fi
    if [ -z "$SETTINGS" ]; then
        die "Please add --settings flag to specify which settings file to use."
    fi
    if [ -z "$COUNT" ]; then
        COUNT=$(awk '/^clustersize:/ {print $2}' $SETTINGS)
        warning "No --count option was specified. Using value from settings file ($COUNT)."
    fi
    
    # Check that the specified settings and infrastructure are valid.        
    need_settings $SETTINGS
    need_infra $INFRA

    if [ -z "$TAG" ]; then
        TAG=$(make_tag)
    fi
    mkdir -p tags/$TAG
    ln -s ../../$INFRA tags/$TAG/infra.sh
    ln -s ../../$SETTINGS tags/$TAG/settings.yaml
    echo creating > tags/$TAG/status

    infra_start $COUNT
    sep
    info "Successfully created $COUNT instances with tag $TAG"
    sep
    echo created > tags/$TAG/status

    info "To deploy Docker on these instances, you can run:"
    info "$0 deploy $TAG"
    info "To terminate these instances, you can run:"
    info "$0 stop $TAG"
}

_cmd stop "Stop (terminate, shutdown, kill, remove, destroy...) instances"
_cmd_stop() {
    TAG=$1
    need_tag
    infra_stop
    echo stopped > tags/$TAG/status
}

_cmd tags "List groups of VMs known locally"
_cmd_tags() {
    (
        cd tags
        echo "[#] [Status] [Tag] [Infra]" \
           | awk '{ printf "%-7s %-12s %-25s %-25s\n", $1, $2, $3, $4}'
        for tag in *; do
            if [ -f $tag/ips.txt ]; then
                count="$(wc -l < $tag/ips.txt)"
            else
                count="?"
            fi
            if [ -f $tag/status ]; then
                status="$(cat $tag/status)"
            else
                status="?"
            fi
            if [ -f $tag/infra.sh ]; then
                infra="$(basename $(readlink $tag/infra.sh))"
            else
                infra="?"
            fi
            echo "$count $status $tag $infra" \
               | awk '{ printf "%-7s %-12s %-25s %-25s\n", $1, $2, $3, $4}'
        done
    )
}

_cmd test "Run tests (pre-flight checks) on a group of VMs"
_cmd_test() {
    TAG=$1
    need_tag
    test_tag
}

greet() {
    IAMUSER=$(aws iam get-user --query 'User.UserName')
    info "Hello! You seem to be UNIX user $USER, and IAM user $IAMUSER."
}

pull_tag() {
    # Pre-pull a bunch of images
    pssh --timeout 900 'for I in \
        debian:latest \
        ubuntu:latest \
        fedora:latest \
        centos:latest \
        elasticsearch:2 \
        postgres \
        redis \
        alpine \
        registry \
        nicolaka/netshoot \
        jpetazzo/trainingwheels \
        golang \
        training/namer \
        dockercoins/hasher \
        dockercoins/rng \
        dockercoins/webui \
        dockercoins/worker \
        logstash \
        prom/node-exporter \
        google/cadvisor \
        dockersamples/visualizer \
        nathanleclaire/redisonrails; do
        sudo -u docker docker pull $I
    done'

    info "Finished pulling images for $TAG."
}

tag_is_reachable() {
    pssh -t 5 true 2>&1 >/dev/null
}

test_tag() {
    ips_file=tags/$TAG/ips.txt
    info "Picking a random IP address in $ips_file to run tests."
    ip=$(shuf -n1 $ips_file)
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

make_tag() {
    if [ -z $USER ]; then
        export USER=anonymous
    fi
    date +%Y-%m-%d-%H-%M-$USER
}

describe_tag() {
    FIXME
    # Display instance details and reachability/status information
    TAG=$1
    need_tag $TAG
    aws_display_instances_by_tag $TAG
    aws_display_instance_statuses_by_tag $TAG
}
