export AWS_DEFAULT_OUTPUT=text

HELP=""
_cmd() {
    HELP="$(printf "%s\n%-20s %s\n" "$HELP" "$1" "$2")"
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

    ln -sf ../tags/$TAG/ips.html www/$TAG.html
    ln -sf ../tags/$TAG/ips.pdf www/$TAG.pdf

    info "Cards created. You can view them with:"
    info "xdg-open tags/$TAG/ips.html tags/$TAG/ips.pdf (on Linux)"
    info "open tags/$TAG/ips.html (on macOS)"
    info "Or you can start a web server with:"
    info "$0 www"
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

    # Wait for cloudinit to be done
    pssh "
    while [ ! -f /var/lib/cloud/instance/boot-finished ]; do
        sleep 1
    done"

    # Special case for scaleway since it doesn't come with sudo
    if [ "$INFRACLASS" = "scaleway" ]; then
        pssh -l root "
    grep DEBIAN_FRONTEND /etc/environment || echo DEBIAN_FRONTEND=noninteractive >> /etc/environment
    grep cloud-init /etc/sudoers && rm /etc/sudoers
    apt-get update && apt-get install sudo -y"
    fi

    # FIXME
    # Special case for hetzner since it doesn't have an ubuntu user
    #if [ "$INFRACLASS" = "hetzner" ]; then
    #    pssh -l root "
    #[ -d /home/ubuntu ] ||
    #    useradd ubuntu -m -s /bin/bash
    #echo 'ubuntu ALL=(ALL:ALL) NOPASSWD:ALL' > /etc/sudoers.d/ubuntu
    #[ -d /home/ubuntu/.ssh ] ||
    #    install --owner=ubuntu --mode=700 --directory /home/ubuntu/.ssh
    #[ -f /home/ubuntu/.ssh/authorized_keys ] ||
    #    install --owner=ubuntu --mode=600 /root/.ssh/authorized_keys --target-directory /home/ubuntu/.ssh"
    #fi

    # Copy settings and install Python YAML parser
    pssh -I tee /tmp/settings.yaml <tags/$TAG/settings.yaml
    pssh "
    sudo apt-get update &&
    sudo apt-get install -y python-yaml"

    # Copy postprep.py to the remote machines, and execute it, feeding it the list of IP addresses
    pssh -I tee /tmp/postprep.py <lib/postprep.py
    pssh --timeout 900 --send-input "python /tmp/postprep.py >>/tmp/pp.out 2>>/tmp/pp.err" <tags/$TAG/ips.txt

    # Install docker-prompt script
    pssh -I sudo tee /usr/local/bin/docker-prompt <lib/docker-prompt
    pssh sudo chmod +x /usr/local/bin/docker-prompt

    # If /home/docker/.ssh/id_rsa doesn't exist, copy it from the first node
    pssh "
    sudo -u docker [ -f /home/docker/.ssh/id_rsa ] ||
    ssh -o StrictHostKeyChecking=no \$(cat /etc/name_of_first_node) sudo -u docker tar -C /home/docker -cvf- .ssh |
    sudo -u docker tar -C /home/docker -xf-"

    # if 'docker@' doesn't appear in /home/docker/.ssh/authorized_keys, copy it there
    pssh "
    grep docker@ /home/docker/.ssh/authorized_keys ||
    cat /home/docker/.ssh/id_rsa.pub |
    sudo -u docker tee -a /home/docker/.ssh/authorized_keys"

    # On the first node, create and deploy TLS certs using Docker Machine
    # (Currently disabled.)
    true || pssh "
    if i_am_first_node; then
        grep '[0-9]\$' /etc/hosts |
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

_cmd disabledocker "Stop Docker Engine and don't restart it automatically"
_cmd_disabledocker() {
    TAG=$1
    need_tag

    pssh "
    sudo systemctl disable docker.service
    sudo systemctl disable docker.socket
    sudo systemctl stop docker
    sudo killall containerd
    "
}

_cmd kubebins "Install Kubernetes and CNI binaries but don't start anything"
_cmd_kubebins() {
    TAG=$1
    need_tag

    pssh --timeout 300 "
    set -e
    cd /usr/local/bin
    if ! [ -x etcd ]; then
        ##VERSION##
        curl -L https://github.com/etcd-io/etcd/releases/download/v3.4.9/etcd-v3.4.9-linux-amd64.tar.gz \
        | sudo tar --strip-components=1 --wildcards -zx '*/etcd' '*/etcdctl'
    fi
    if ! [ -x hyperkube ]; then
        ##VERSION##
        curl -L https://dl.k8s.io/v1.18.8/kubernetes-server-linux-amd64.tar.gz \
        | sudo tar --strip-components=3 -zx \
          kubernetes/server/bin/kube{ctl,let,-proxy,-apiserver,-scheduler,-controller-manager}
    fi
    sudo mkdir -p /opt/cni/bin
    cd /opt/cni/bin
    if ! [ -x bridge ]; then
        curl -L https://github.com/containernetworking/plugins/releases/download/v0.8.6/cni-plugins-linux-amd64-v0.8.6.tgz \
        | sudo tar -zx
    fi
    "
}

_cmd kube "Setup kubernetes clusters with kubeadm (must be run AFTER deploy)"
_cmd_kube() {
    TAG=$1
    need_tag

    # Optional version, e.g. 1.13.5
    KUBEVERSION=$2
    if [ "$KUBEVERSION" ]; then
        EXTRA_APTGET="=$KUBEVERSION-00"
        EXTRA_KUBEADM="--kubernetes-version=v$KUBEVERSION"
    else
        EXTRA_APTGET=""
        EXTRA_KUBEADM=""
    fi

    # Install packages
    pssh --timeout 200 "
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg |
    sudo apt-key add - &&
    echo deb http://apt.kubernetes.io/ kubernetes-xenial main |
    sudo tee /etc/apt/sources.list.d/kubernetes.list"
    pssh --timeout 200 "
    sudo apt-get update -q &&
    sudo apt-get install -qy kubelet$EXTRA_APTGET kubeadm$EXTRA_APTGET kubectl$EXTRA_APTGET &&
    kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl"

    # Initialize kube master
    pssh --timeout 200 "
    if i_am_first_node && [ ! -f /etc/kubernetes/admin.conf ]; then
        kubeadm token generate > /tmp/token &&
	sudo kubeadm init $EXTRA_KUBEADM --token \$(cat /tmp/token) --apiserver-cert-extra-sans \$(cat /tmp/ipv4) --ignore-preflight-errors=NumCPU
    fi"

    # Put kubeconfig in ubuntu's and docker's accounts
    pssh "
    if i_am_first_node; then
        sudo mkdir -p \$HOME/.kube /home/docker/.kube &&
        sudo cp /etc/kubernetes/admin.conf \$HOME/.kube/config &&
        sudo cp /etc/kubernetes/admin.conf /home/docker/.kube/config &&
        sudo chown -R \$(id -u) \$HOME/.kube &&
        sudo chown -R docker /home/docker/.kube
    fi"

    # Install weave as the pod network
    pssh "
    if i_am_first_node; then
        kubever=\$(kubectl version | base64 | tr -d '\n') &&
        kubectl apply -f https://cloud.weave.works/k8s/net?k8s-version=\$kubever
    fi"

    # Join the other nodes to the cluster
    pssh --timeout 200 "
    if ! i_am_first_node && [ ! -f /etc/kubernetes/kubelet.conf ]; then
        FIRSTNODE=\$(cat /etc/name_of_first_node) &&
        TOKEN=\$(ssh -o StrictHostKeyChecking=no \$FIRSTNODE cat /tmp/token) &&
        sudo kubeadm join --discovery-token-unsafe-skip-ca-verification --token \$TOKEN \$FIRSTNODE:6443
    fi"

    # Install metrics server
    pssh "
    if i_am_first_node; then
	kubectl apply -f https://raw.githubusercontent.com/jpetazzo/container.training/master/k8s/metrics-server.yaml
    fi"

    # Install kubectx and kubens
    pssh "
    [ -d kubectx ] || git clone https://github.com/ahmetb/kubectx &&
    sudo ln -sf \$HOME/kubectx/kubectx /usr/local/bin/kctx &&
    sudo ln -sf \$HOME/kubectx/kubens /usr/local/bin/kns &&
    sudo cp \$HOME/kubectx/completion/*.bash /etc/bash_completion.d &&
    [ -d kube-ps1 ] || git clone https://github.com/jonmosco/kube-ps1 &&
    sudo -u docker sed -i s/docker-prompt/kube_ps1/ /home/docker/.bashrc &&
    sudo -u docker tee -a /home/docker/.bashrc <<EOF
. \$HOME/kube-ps1/kube-ps1.sh
KUBE_PS1_PREFIX=""
KUBE_PS1_SUFFIX=""
KUBE_PS1_SYMBOL_ENABLE="false"
KUBE_PS1_CTX_COLOR="green"
KUBE_PS1_NS_COLOR="green"
EOF"

    # Install stern
    pssh "
    if [ ! -x /usr/local/bin/stern ]; then
        ##VERSION##
        sudo curl -L -o /usr/local/bin/stern https://github.com/wercker/stern/releases/download/1.11.0/stern_linux_amd64 &&
        sudo chmod +x /usr/local/bin/stern &&
        stern --completion bash | sudo tee /etc/bash_completion.d/stern
    fi"

    # Install helm
    pssh "
    if [ ! -x /usr/local/bin/helm ]; then
        curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get-helm-3 | sudo bash &&
        helm completion bash | sudo tee /etc/bash_completion.d/helm
    fi"

    # Install kustomize
    pssh "
    if [ ! -x /usr/local/bin/kustomize ]; then
        ##VERSION##
        curl -L https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/v3.6.1/kustomize_v3.6.1_linux_amd64.tar.gz |
            sudo tar -C /usr/local/bin -zx kustomize
        echo complete -C /usr/local/bin/kustomize kustomize | sudo tee /etc/bash_completion.d/kustomize
    fi"

    # Install ship
    # Note: 0.51.3 is the last version that doesn't display GIN-debug messages
    # (don't want to get folks confused by that!)
    pssh "
    if [ ! -x /usr/local/bin/ship ]; then
        ##VERSION##
        curl -L https://github.com/replicatedhq/ship/releases/download/v0.51.3/ship_0.51.3_linux_amd64.tar.gz |
             sudo tar -C /usr/local/bin -zx ship
    fi"

    # Install the AWS IAM authenticator
    pssh "
    if [ ! -x /usr/local/bin/aws-iam-authenticator ]; then
	    ##VERSION##
        sudo curl -o /usr/local/bin/aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.12.7/2019-03-27/bin/linux/amd64/aws-iam-authenticator
	sudo chmod +x /usr/local/bin/aws-iam-authenticator
    fi"

    sep "Done"
}

_cmd kubereset "Wipe out Kubernetes configuration on all nodes"
_cmd_kubereset() {
    TAG=$1
    need_tag

    pssh "sudo kubeadm reset --force"
}

_cmd kubetest "Check that all nodes are reporting as Ready"
_cmd_kubetest() {
    TAG=$1
    need_tag

    # There are way too many backslashes in the command below.
    # Feel free to make that better ♥
    pssh "
    set -e
    if i_am_first_node; then
      which kubectl
      for NODE in \$(grep [0-9]\$ /etc/hosts | grep -v ^127 | awk {print\ \\\$2}); do
        echo \$NODE ; kubectl get nodes | grep -w \$NODE | grep -w Ready
      done
    fi"
}

_cmd ips "Show the IP addresses for a given tag"
_cmd_ips() {
    TAG=$1
    need_tag $TAG

    SETTINGS=tags/$TAG/settings.yaml
    CLUSTERSIZE=$(awk '/^clustersize:/ {print $2}' $SETTINGS)
    while true; do
        for I in $(seq $CLUSTERSIZE); do
            read ip || return 0
            printf "%s\t" "$ip"
        done
        printf "\n"
    done < tags/$TAG/ips.txt
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

_cmd maketag "Generate a quasi-unique tag for a group of instances"
_cmd_maketag() {
    if [ -z $USER ]; then
        export USER=anonymous
    fi
    MS=$(($(date +%N | tr -d 0)/1000000))
    date +%Y-%m-%d-%H-%M-$MS-$USER
}

_cmd ping "Ping VMs in a given tag, to check that they have network access"
_cmd_ping() {
    TAG=$1
    need_tag

    fping < tags/$TAG/ips.txt
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

_cmd tailhist "Install history viewer on port 1088"
_cmd_tailhist () {
    TAG=$1
    need_tag

    pssh "
    wget https://github.com/joewalnes/websocketd/releases/download/v0.3.0/websocketd-0.3.0_amd64.deb
    sudo dpkg -i websocketd-0.3.0_amd64.deb
    sudo mkdir -p /tmp/tailhist
    sudo tee /root/tailhist.service <<EOF
[Unit]
Description=tailhist

[Install]
WantedBy=multi-user.target

[Service]
WorkingDirectory=/tmp/tailhist
ExecStart=/usr/bin/websocketd --port=1088 --staticdir=. sh -c \"tail -n +1 -f /home/docker/.history || echo 'Could not read history file. Perhaps you need to \\\"chmod +r .history\\\"?'\"
User=nobody
Group=nogroup
Restart=always
EOF
    sudo systemctl enable /root/tailhist.service
    sudo systemctl start tailhist"
    pssh -I sudo tee /tmp/tailhist/index.html <lib/tailhist.html
}

_cmd opensg "Open the default security group to ALL ingress traffic"
_cmd_opensg() {
    need_infra $1
    infra_opensg
}

_cmd disableaddrchecks "Disable source/destination IP address checks"
_cmd_disableaddrchecks() {
    TAG=$1
    need_tag

    infra_disableaddrchecks
}

_cmd pssh "Run an arbitrary command on all nodes"
_cmd_pssh() {
    TAG=$1
    need_tag
    shift

    pssh "$@"
}

_cmd pull_images "Pre-pull a bunch of Docker images"
_cmd_pull_images() {
    TAG=$1
    need_tag
    pull_tag
}

_cmd remap_nodeports "Remap NodePort range to 10000-10999"
_cmd_remap_nodeports() {
    TAG=$1
    need_tag

    FIND_LINE="    - --service-cluster-ip-range=10.96.0.0\/12"
    ADD_LINE="    - --service-node-port-range=10000-10999"
    MANIFEST_FILE=/etc/kubernetes/manifests/kube-apiserver.yaml
    pssh "
    if i_am_first_node && ! grep -q '$ADD_LINE' $MANIFEST_FILE; then
        sudo sed -i 's/\($FIND_LINE\)\$/\1\n$ADD_LINE/' $MANIFEST_FILE
    fi"
}

_cmd quotas "Check our infrastructure quotas (max instances)"
_cmd_quotas() {
    need_infra $1
    infra_quotas
}

_cmd ssh "Open an SSH session to the first node of a tag"
_cmd_ssh() {
    TAG=$1
    need_tag
    IP=$(head -1 tags/$TAG/ips.txt)
    info "Logging into $IP"
    ssh docker@$IP
}

_cmd start "Start a group of VMs"
_cmd_start() {
    while [ ! -z "$*" ]; do
        case "$1" in
        --infra) INFRA=$2; shift 2;;
        --settings) SETTINGS=$2; shift 2;;
        --count) COUNT=$2; shift 2;;
        --tag) TAG=$2; shift 2;;
        --students) STUDENTS=$2; shift 2;;
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
        CLUSTERSIZE=$(awk '/^clustersize:/ {print $2}' $SETTINGS)
        if [ -z "$STUDENTS" ]; then
            warning "Neither --count nor --students was specified."
            warning "According to the settings file, the cluster size is $CLUSTERSIZE."
            warning "Deploying one cluster of $CLUSTERSIZE nodes."
            STUDENTS=1
        fi
        COUNT=$(($STUDENTS*$CLUSTERSIZE))
    fi

    # Check that the specified settings and infrastructure are valid.
    need_settings $SETTINGS
    need_infra $INFRA

    if [ -z "$TAG" ]; then
        TAG=$(_cmd_maketag)
    fi
    mkdir -p tags/$TAG
    ln -s ../../$INFRA tags/$TAG/infra.sh
    ln -s ../../$SETTINGS tags/$TAG/settings.yaml
    echo creating > tags/$TAG/status

    infra_start $COUNT
    sep
    info "Successfully created $COUNT instances with tag $TAG"
    echo created > tags/$TAG/status

    # If the settings.yaml file has a "steps" field,
    # automatically execute all the actions listed in that field.
    # If an action fails, retry it up to 10 times.
    python -c 'if True: # hack to deal with indentation
        import sys, yaml
        settings = yaml.safe_load(sys.stdin)
        print ("\n".join(settings.get("steps", [])))
        ' < tags/$TAG/settings.yaml \
    | while read step; do
        if [ -z "$step" ]; then
            break
        fi
        sep
        info "Automatically executing step '$step'."
        TRY=1
        MAXTRY=10
        while ! $0 $step $TAG ; do
            TRY=$(($TRY+1))
            if [ $TRY -gt $MAXTRY ]; then
                error "This step ($step) failed after $MAXTRY attempts."
                info "You can troubleshoot the situation manually, or terminate these instances with:"
                info "$0 stop $TAG"
                die "Giving up."
            else
                sep
                info "Step '$step' failed. Let's wait 10 seconds and try again."
                info "(Attempt $TRY out of $MAXTRY.)"
                sleep 10
            fi
        done
    done
    sep
    info "Deployment successful."
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

_cmd tmux "Log into the first node and start a tmux server"
_cmd_tmux() {
    TAG=$1
    need_tag
    IP=$(head -1 tags/$TAG/ips.txt)
    info "Opening ssh+tmux with $IP"
    rm -f /tmp/tmux-$UID/default
    ssh -t -L /tmp/tmux-$UID/default:/tmp/tmux-1001/default docker@$IP tmux new-session -As 0
}

_cmd helmprom "Install Helm and Prometheus"
_cmd_helmprom() {
    TAG=$1
    need_tag
    pssh "
    if i_am_first_node; then
        sudo -u docker -H helm repo add stable https://kubernetes-charts.storage.googleapis.com/
        sudo -u docker -H helm install prometheus stable/prometheus \
            --namespace kube-system \
            --set server.service.type=NodePort \
            --set server.service.nodePort=30090 \
            --set server.persistentVolume.enabled=false \
            --set alertmanager.enabled=false
    fi"
}

# Sometimes, weave fails to come up on some nodes.
# Symptom: the pods on a node are unreachable (they don't even ping).
# Remedy: wipe out Weave state and delete weave pod on that node.
# Specifically, identify the weave pod that is defective, then:
# kubectl -n kube-system exec weave-net-XXXXX -c weave rm /weavedb/weave-netdata.db
# kubectl -n kube-system delete pod weave-net-XXXXX
_cmd weavetest "Check that weave seems properly setup"
_cmd_weavetest() {
    TAG=$1
    need_tag
    pssh "
    kubectl -n kube-system get pods -o name | grep weave | cut -d/ -f2 |
    xargs -I POD kubectl -n kube-system exec POD -c weave -- \
    sh -c \"./weave --local status | grep Connections | grep -q ' 1 failed' || ! echo POD \""
}

_cmd webssh "Install a WEB SSH server on the machines (port 1080)"
_cmd_webssh() {
    TAG=$1
    need_tag
    pssh "
    sudo apt-get update &&
    sudo apt-get install python-tornado python-paramiko -y"
    pssh "
    cd /opt
    [ -d webssh ] || sudo git clone https://github.com/jpetazzo/webssh"
    pssh "
    for KEYFILE in /etc/ssh/*.pub; do
      read a b c < \$KEYFILE; echo localhost \$a \$b
    done | sudo tee /opt/webssh/known_hosts"
    pssh "cat >webssh.service <<EOF
[Unit]
Description=webssh

[Install]
WantedBy=multi-user.target

[Service]
WorkingDirectory=/opt/webssh
ExecStart=/usr/bin/env python run.py --fbidhttp=false --port=1080 --policy=reject
User=nobody
Group=nogroup
Restart=always
EOF"
    pssh "
    sudo systemctl enable \$PWD/webssh.service &&
    sudo systemctl start webssh.service"
}

_cmd www "Run a web server to access card HTML and PDF"
_cmd_www() {
    cd www
    IPADDR=$(curl -sL canihazip.com/s)
    info "The following files are available:"
    for F in *; do
        echo "http://$IPADDR:8000/$F"
    done
    info "Press Ctrl-C to stop server."
    python3 -m http.server
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
        "ls -l /usr/local/bin/i_am_first_node" \
        "grep . /etc/name_of_first_node /etc/ipv4_of_first_node" \
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
