export AWS_DEFAULT_OUTPUT=text

# Ignore SSH key validation when connecting to these remote hosts.
# (Otherwise, deployment scripts break when a VM IP address reuse.)
SSHOPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"

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

_cmd clean "Remove information about stopped clusters"
_cmd_clean() {
	for TAG in tags/*; do
		if grep -q ^stopped$ "$TAG/status"; then
			info "Removing $TAG..."
			rm -rf "$TAG"
		fi
	done	
}

_cmd createuser "Create the user that students will use"
_cmd_createuser() {
    TAG=$1
    need_tag
    need_login_password

    pssh "
    set -e
    # Create the user if it doesn't exist yet.
    id $USER_LOGIN || sudo useradd -d /home/$USER_LOGIN -g users -m -s /bin/bash $USER_LOGIN
    # Add them to the docker group, if there is one.
    grep ^docker: /etc/group && sudo usermod -aG docker $USER_LOGIN
    # Set their password.
    echo $USER_LOGIN:$USER_PASSWORD | sudo chpasswd
    # Add them to sudoers and allow passwordless authentication.
    echo '$USER_LOGIN ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/$USER_LOGIN
    "

    # The MaxAuthTries is here to help with folks who have many SSH keys.
    pssh "
    set -e
    sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
    sudo sed -i 's/#MaxAuthTries 6/MaxAuthTries 42/' /etc/ssh/sshd_config
    sudo service ssh restart
    "

    pssh "
    set -e
    cd /home/$USER_LOGIN
    sudo -u $USER_LOGIN mkdir -p .ssh
    if i_am_first_node; then
      # Generate a key pair with an empty passphrase.
      if ! sudo -u $USER_LOGIN [ -f .ssh/id_rsa ]; then
        sudo -u $USER_LOGIN ssh-keygen -t rsa -f .ssh/id_rsa -P ''
        sudo -u $USER_LOGIN cp .ssh/id_rsa.pub .ssh/authorized_keys
      fi
    fi
    "

    pssh "
    set -e
    cd /home/$USER_LOGIN
    if ! i_am_first_node; then
      # Copy keys from the first node.
      ssh $SSHOPTS \$(cat /etc/name_of_first_node) sudo -u $USER_LOGIN tar -C /home/$USER_LOGIN -cvf- .ssh |
      sudo -u $USER_LOGIN tar -xf-
    fi
    "

    # FIXME do this only once.
    pssh -I "sudo -u $USER_LOGIN tee -a /home/$USER_LOGIN/.bashrc" <<"SQRL"

# Fancy prompt courtesy of @soulshake.
export PS1='\e[1m\e[31m[$HOSTIP] \e[32m($(docker-prompt)) \e[34m\u@\h\e[35m \w\e[0m\n$ '

# Bigger history, in a different file, and saved before executing each command.
export HISTSIZE=9999
export HISTFILESIZE=9999
shopt -s histappend
trap 'history -a' DEBUG
export HISTFILE=~/.history
SQRL

    pssh -I "sudo -u $USER_LOGIN tee /home/$USER_LOGIN/.vimrc" <<SQRL
syntax on
set autoindent
set expandtab
set number
set shiftwidth=2
set softtabstop=2
set nowrap
SQRL

    pssh -I "sudo -u $USER_LOGIN tee /home/$USER_LOGIN/.tmux.conf" <<SQRL
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# Allow using mouse to switch panes
set -g mouse on

# Make scrolling with wheels work

bind -n WheelUpPane if-shell -F -t = "#{mouse_any_flag}" "send-keys -M" "if -Ft= '#{pane_in_mode}' 'send-keys -M' 'select-pane -t=; copy-mode -e; send-keys -M'"
bind -n WheelDownPane select-pane -t= \; send-keys -M
SQRL

    # Install docker-prompt script
    pssh -I sudo tee /usr/local/bin/docker-prompt <lib/docker-prompt
    pssh sudo chmod +x /usr/local/bin/docker-prompt

    echo user_ok > tags/$TAG/status
}

_cmd clusterize "Group VMs in clusters"
_cmd_clusterize() {
    TAG=$1
    need_tag

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

    # Special case for oracle since their iptables blocks everything but SSH
    pssh "
    if [ -f /etc/iptables/rules.v4 ]; then
        sudo sed -i 's/-A INPUT -j REJECT --reject-with icmp-host-prohibited//' /etc/iptables/rules.v4
        sudo netfilter-persistent start
    fi"

    # Copy settings and install Python YAML parser
    pssh -I tee /tmp/settings.yaml <tags/$TAG/settings.yaml
    pssh "
    sudo apt-get update &&
    sudo apt-get install -y python-yaml"

    # If there is no "python" binary, symlink to python3
    pssh "
    if ! which python; then
        sudo ln -s $(which python3) /usr/local/bin/python
    fi"

    # Copy postprep.py to the remote machines, and execute it, feeding it the list of IP addresses
    pssh -I tee /tmp/clusterize.py <lib/clusterize.py
    pssh --timeout 900 --send-input "python /tmp/clusterize.py >>/tmp/pp.out 2>>/tmp/pp.err" <tags/$TAG/ips.txt

    # On the first node, create and deploy TLS certs using Docker Machine
    # (Currently disabled.)
    true || pssh "
    if i_am_first_node; then
        grep '[0-9]\$' /etc/hosts |
        xargs -n2 sudo -H -u $USER_LOGIN \
        docker-machine create -d generic --generic-ssh-user $USER_LOGIN --generic-ip-address
    fi"

    echo cluster_ok > tags/$TAG/status
}

_cmd disabledocker "Stop Docker Engine and don't restart it automatically"
_cmd_disabledocker() {
    TAG=$1
    need_tag

    pssh "
    sudo systemctl disable docker.socket --now
    sudo systemctl disable docker.service --now
    sudo systemctl disable containerd.service --now
    "
}

_cmd docker "Install and start Docker"
_cmd_docker() {
    TAG=$1
    need_tag

    pssh "
    set -e
    # On EC2, the ephemeral disk might be mounted on /mnt.
    # If /mnt is a mountpoint, place Docker workspace on it.
    if mountpoint -q /mnt; then
      sudo mkdir -p /mnt/docker
      sudo ln -sfn /mnt/docker /var/lib/docker
    fi

    # This will install the latest Docker.
    sudo apt-get -qy install apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository 'deb https://download.docker.com/linux/ubuntu bionic stable'
    sudo apt-get -q update
    sudo apt-get -qy install docker-ce

    # Add registry mirror configuration.
    if ! [ -f /etc/docker/daemon.json ]; then
        echo '{\"registry-mirrors\": [\"https://mirror.gcr.io\"]}' | sudo tee /etc/docker/daemon.json
        sudo systemctl restart docker
    fi
    "

    ##VERSION## https://github.com/docker/compose/releases
    if [ "$ARCHITECTURE" ]; then
        COMPOSE_VERSION=v2.2.3
        COMPOSE_PLATFORM='linux-$(uname -m)'
    else
        COMPOSE_VERSION=1.29.2
        COMPOSE_PLATFORM='Linux-$(uname -m)'
    fi
    pssh "
    set -e
    ### Install docker-compose.
    sudo curl -fsSL -o /usr/local/bin/docker-compose \
      https://github.com/docker/compose/releases/download/$COMPOSE_VERSION/docker-compose-$COMPOSE_PLATFORM
    sudo chmod +x /usr/local/bin/docker-compose
    docker-compose version

    ### Install docker-machine.
    ##VERSION## https://github.com/docker/machine/releases
    MACHINE_VERSION=v0.16.2
    sudo curl -fsSL -o /usr/local/bin/docker-machine \
      https://github.com/docker/machine/releases/download/\$MACHINE_VERSION/docker-machine-\$(uname -s)-\$(uname -m)
    sudo chmod +x /usr/local/bin/docker-machine
    docker-machine version
    "
}

_cmd kubebins "Install Kubernetes and CNI binaries but don't start anything"
_cmd_kubebins() {
    TAG=$1
    need_tag

    ##VERSION##
    ETCD_VERSION=v3.4.13
    K8SBIN_VERSION=v1.19.11 # Can't go to 1.20 because it requires a serviceaccount signing key.
    CNI_VERSION=v0.8.7
    ARCH=${ARCHITECTURE-amd64}
    pssh --timeout 300 "
    set -e
    cd /usr/local/bin
    if ! [ -x etcd ]; then
        curl -L https://github.com/etcd-io/etcd/releases/download/$ETCD_VERSION/etcd-$ETCD_VERSION-linux-$ARCH.tar.gz \
        | sudo tar --strip-components=1 --wildcards -zx '*/etcd' '*/etcdctl'
    fi
    if ! [ -x hyperkube ]; then
        ##VERSION##
        curl -L https://dl.k8s.io/$K8SBIN_VERSION/kubernetes-server-linux-$ARCH.tar.gz \
        | sudo tar --strip-components=3 -zx \
          kubernetes/server/bin/kube{ctl,let,-proxy,-apiserver,-scheduler,-controller-manager}
    fi
    sudo mkdir -p /opt/cni/bin
    cd /opt/cni/bin
    if ! [ -x bridge ]; then
        curl -L https://github.com/containernetworking/plugins/releases/download/$CNI_VERSION/cni-plugins-linux-$ARCH-$CNI_VERSION.tgz \
        | sudo tar -zx
    fi
    "
}

_cmd kube "Setup kubernetes clusters with kubeadm (must be run AFTER deploy)"
_cmd_kube() {
    TAG=$1
    need_tag
    need_login_password

    # Optional version, e.g. 1.13.5
    SETTINGS=tags/$TAG/settings.yaml
    KUBEVERSION=$(awk '/^kubernetes_version:/ {print $2}' $SETTINGS)
    if [ "$KUBEVERSION" ]; then
        pssh "
        sudo tee /etc/apt/preferences.d/kubernetes <<EOF
Package: kubectl kubeadm kubelet
Pin: version $KUBEVERSION*
Pin-Priority: 1000
EOF"
    fi

    # Install packages
    pssh --timeout 200 "
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg |
    sudo apt-key add - &&
    echo deb http://apt.kubernetes.io/ kubernetes-xenial main |
    sudo tee /etc/apt/sources.list.d/kubernetes.list"
    pssh --timeout 200 "
    sudo apt-get update -q &&
    sudo apt-get install -qy kubelet kubeadm kubectl &&
    sudo apt-mark hold kubelet kubeadm kubectl
    kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl &&
    echo 'alias k=kubectl' | sudo tee /etc/bash_completion.d/k &&
    echo 'complete -F __start_kubectl k' | sudo tee -a /etc/bash_completion.d/k"

    # Disable swap
    # (note that this won't survive across node reboots!)
    if [ "$INFRACLASS" = "linode" ]; then
        pssh "
        sudo swapoff -a"
    fi

    # Re-enable CRI interface in containerd
    pssh "
    echo '# Use default parameters for containerd.' | sudo tee /etc/containerd/config.toml
    sudo systemctl restart containerd"

    # Initialize kube control plane
    pssh --timeout 200 "
    if i_am_first_node && [ ! -f /etc/kubernetes/admin.conf ]; then
        kubeadm token generate > /tmp/token &&
        cat >/tmp/kubeadm-config.yaml <<EOF
kind: InitConfiguration
apiVersion: kubeadm.k8s.io/v1beta2
bootstrapTokens:
- token: \$(cat /tmp/token)
nodeRegistration:
  # Comment out the next line to switch back to Docker.
  criSocket: /run/containerd/containerd.sock
  ignorePreflightErrors:
  - NumCPU
---
kind: JoinConfiguration
apiVersion: kubeadm.k8s.io/v1beta2
discovery:
  bootstrapToken:
    apiServerEndpoint: \$(cat /etc/name_of_first_node):6443
    token: \$(cat /tmp/token)
    unsafeSkipCAVerification: true
nodeRegistration:
  # Comment out the next line to switch back to Docker.
  criSocket: /run/containerd/containerd.sock
  ignorePreflightErrors:
  - NumCPU
---
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
# The following line is necessary when using Docker.
# It doesn't seem necessary when using containerd.
#cgroupDriver: cgroupfs
---
kind: ClusterConfiguration
apiVersion: kubeadm.k8s.io/v1beta2
apiServer:
  certSANs:
  - \$(cat /tmp/ipv4)
EOF
	sudo kubeadm init --config=/tmp/kubeadm-config.yaml
    fi"

    # Put kubeconfig in ubuntu's and $USER_LOGIN's accounts
    pssh "
    if i_am_first_node; then
        sudo mkdir -p \$HOME/.kube /home/$USER_LOGIN/.kube &&
        sudo cp /etc/kubernetes/admin.conf \$HOME/.kube/config &&
        sudo cp /etc/kubernetes/admin.conf /home/$USER_LOGIN/.kube/config &&
        sudo chown -R \$(id -u) \$HOME/.kube &&
        sudo chown -R $USER_LOGIN /home/$USER_LOGIN/.kube
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
        ssh $SSHOPTS \$FIRSTNODE cat /tmp/kubeadm-config.yaml > /tmp/kubeadm-config.yaml &&
        sudo kubeadm join --config /tmp/kubeadm-config.yaml
    fi"

    # Install metrics server
    pssh "
    if i_am_first_node; then
	kubectl apply -f https://raw.githubusercontent.com/jpetazzo/container.training/master/k8s/metrics-server.yaml
    #helm upgrade --install metrics-server \
    #     --repo https://kubernetes-sigs.github.io/metrics-server/ metrics-server \
    #     --namespace kube-system --set args={--kubelet-insecure-tls}
    fi"
}

_cmd kubetools "Install a bunch of CLI tools for Kubernetes"
_cmd_kubetools() {
    TAG=$1
    need_tag
    need_login_password

    ARCH=${ARCHITECTURE-amd64}

    # Folks, please, be consistent!
    # Either pick "uname -m" (on Linux, that's x86_64, aarch64, etc.)
    # Or GOARCH (amd64, arm64, etc.)
    # But don't mix both! Thank you ♥
    case $ARCH in
    amd64)
        HERP_DERP_ARCH=x86_64
        TILT_ARCH=x86_64
        ;;
    *)
        HERP_DERP_ARCH=$ARCH
        TILT_ARCH=${ARCH}_ALPHA
        ;;
    esac

    # Install kubectx and kubens
    pssh "
    set -e
    if ! [ -x /usr/local/bin/kctx ]; then
      cd /tmp
      git clone https://github.com/ahmetb/kubectx
      sudo cp kubectx/kubectx /usr/local/bin/kctx
      sudo cp kubectx/kubens /usr/local/bin/kns
      sudo cp kubectx/completion/*.bash /etc/bash_completion.d
    fi"

    # Install kube-ps1
    pssh "
    set -e
    if ! [ -f /etc/profile.d/kube-ps1.sh ]; then
      cd /tmp
      git clone https://github.com/jonmosco/kube-ps1
      sudo cp kube-ps1/kube-ps1.sh /etc/profile.d/kube-ps1.sh
      sudo -u $USER_LOGIN sed -i s/docker-prompt/kube_ps1/ /home/$USER_LOGIN/.bashrc &&
      sudo -u $USER_LOGIN tee -a /home/$USER_LOGIN/.bashrc <<EOF
KUBE_PS1_PREFIX=""
KUBE_PS1_SUFFIX=""
KUBE_PS1_SYMBOL_ENABLE="false"
KUBE_PS1_CTX_COLOR="green"
KUBE_PS1_NS_COLOR="green"
EOF
    fi"

    # Install stern
    ##VERSION## https://github.com/stern/stern/releases
    STERN_VERSION=1.20.1
    FILENAME=stern_${STERN_VERSION}_linux_${ARCH}
    URL=https://github.com/stern/stern/releases/download/v$STERN_VERSION/$FILENAME.tar.gz
    pssh "
    if [ ! -x /usr/local/bin/stern ]; then
        curl -fsSL $URL |
        sudo tar -C /usr/local/bin -zx --strip-components=1 $FILENAME/stern
        sudo chmod +x /usr/local/bin/stern
        stern --completion bash | sudo tee /etc/bash_completion.d/stern
        stern --version
    fi"

    # Install helm
    pssh "
    if [ ! -x /usr/local/bin/helm ]; then
        curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get-helm-3 | sudo bash &&
        helm completion bash | sudo tee /etc/bash_completion.d/helm
        helm version
    fi"

    # Install kustomize
    ##VERSION## https://github.com/kubernetes-sigs/kustomize/releases
    KUSTOMIZE_VERSION=v4.4.0
    URL=https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_${ARCH}.tar.gz
    pssh "
    if [ ! -x /usr/local/bin/kustomize ]; then
        curl -fsSL $URL |
        sudo tar -C /usr/local/bin -zx kustomize
        kustomize completion bash | sudo tee /etc/bash_completion.d/kustomize
        kustomize version
    fi"

    # Install ship
    # Note: 0.51.3 is the last version that doesn't display GIN-debug messages
    # (don't want to get folks confused by that!)
    # Only install ship on Intel platforms (no ARM 64 builds).
    [ "$ARCH" = "amd64" ] &&
    pssh "
    if [ ! -x /usr/local/bin/ship ]; then
        ##VERSION##
        curl -fsSL https://github.com/replicatedhq/ship/releases/download/v0.51.3/ship_0.51.3_linux_$ARCH.tar.gz |
             sudo tar -C /usr/local/bin -zx ship
    fi"

    # Install the AWS IAM authenticator
    pssh "
    if [ ! -x /usr/local/bin/aws-iam-authenticator ]; then
        ##VERSION##
        sudo curl -fsSLo /usr/local/bin/aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.12.7/2019-03-27/bin/linux/$ARCH/aws-iam-authenticator
	sudo chmod +x /usr/local/bin/aws-iam-authenticator
    aws-iam-authenticator version
    fi"

    # Install the krew package manager
    pssh "
    if [ ! -d /home/$USER_LOGIN/.krew ]; then
        cd /tmp &&
        KREW=krew-linux_$ARCH
        curl -fsSL https://github.com/kubernetes-sigs/krew/releases/latest/download/\$KREW.tar.gz |
        tar -zxf- &&
        sudo -u $USER_LOGIN -H ./\$KREW install krew &&
        echo export PATH=/home/$USER_LOGIN/.krew/bin:\\\$PATH | sudo -u $USER_LOGIN tee -a /home/$USER_LOGIN/.bashrc
    fi"

    # Install k9s
    pssh "
    if [ ! -x /usr/local/bin/k9s ]; then
        FILENAME=k9s_Linux_$HERP_DERP_ARCH.tar.gz &&
        curl -fsSL https://github.com/derailed/k9s/releases/latest/download/\$FILENAME |
        sudo tar -zxvf- -C /usr/local/bin k9s
        k9s version
    fi"

    # Install popeye
    pssh "
    if [ ! -x /usr/local/bin/popeye ]; then
        FILENAME=popeye_Linux_$HERP_DERP_ARCH.tar.gz &&
        curl -fsSL https://github.com/derailed/popeye/releases/latest/download/\$FILENAME |
        sudo tar -zxvf- -C /usr/local/bin popeye
        popeye version
    fi"

    # Install Tilt
    # Official instructions:
    # curl -fsSL https://raw.githubusercontent.com/tilt-dev/tilt/master/scripts/install.sh | bash
    # But the install script is not arch-aware (see https://github.com/tilt-dev/tilt/pull/5050).
    pssh "
    if [ ! -x /usr/local/bin/tilt ]; then
        TILT_VERSION=0.22.15
        FILENAME=tilt.\$TILT_VERSION.linux.$TILT_ARCH.tar.gz
        curl -fsSL https://github.com/tilt-dev/tilt/releases/download/v\$TILT_VERSION/\$FILENAME |
        sudo tar -zxvf- -C /usr/local/bin tilt
        tilt version
    fi"

    # Install Skaffold
    pssh "
    if [ ! -x /usr/local/bin/skaffold ]; then
        curl -fsSLo skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-$ARCH &&
        sudo install skaffold /usr/local/bin/
        skaffold version
    fi"

    # Install Kompose
    pssh "
    if [ ! -x /usr/local/bin/kompose ]; then
        curl -fsSLo kompose https://github.com/kubernetes/kompose/releases/latest/download/kompose-linux-$ARCH &&
        sudo install kompose /usr/local/bin
        kompose version
    fi"

    ##VERSION## https://github.com/bitnami-labs/sealed-secrets/releases
    KUBESEAL_VERSION=0.17.4
    #case $ARCH in
    #amd64) FILENAME=kubeseal-linux-amd64;;
    #arm64) FILENAME=kubeseal-arm64;;
    #*)     FILENAME=nope;;
    #esac
    pssh "
    if [ ! -x /usr/local/bin/kubeseal ]; then
        curl -fsSL https://github.com/bitnami-labs/sealed-secrets/releases/download/v$KUBESEAL_VERSION/kubeseal-$KUBESEAL_VERSION-linux-$ARCH.tar.gz |
        sudo tar -zxvf- -C /usr/local/bin kubeseal
        kubeseal --version
    fi"
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
    echo kube_ok > tags/$TAG/status
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

_cmd inventory "List all VMs on a given infrastructure (or all infras if no arg given)"
_cmd_inventory() {
    case "$1" in
    "")
        for INFRA in infra/*; do
            $0 inventory $INFRA
        done
        ;;
    */example.*)
        ;;
    *)
        need_infra $1
        sep "Listing instances for $1"
        infra_list
        ;;
    esac
}

_cmd maketag "Generate a quasi-unique tag for a group of instances"
_cmd_maketag() {
    if [ -z $USER ]; then
        export USER=anonymous
    fi
    MS=$(($(date +%N | tr -d 0)/1000000))
    date +%Y-%m-%d-%H-%M-$MS-$USER
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

_cmd ping "Ping VMs in a given tag, to check that they have network access"
_cmd_ping() {
    TAG=$1
    need_tag

    fping < tags/$TAG/ips.txt
}

_cmd tailhist "Install history viewer on port 1088"
_cmd_tailhist () {
    TAG=$1
    need_tag
    need_login_password

    ARCH=${ARCHITECTURE-amd64}
    [ "$ARCH" = "aarch64" ] && ARCH=arm64

    pssh "
    set -e
    wget https://github.com/joewalnes/websocketd/releases/download/v0.3.0/websocketd-0.3.0-linux_$ARCH.zip
    unzip websocketd-0.3.0-linux_$ARCH.zip websocketd
    sudo mv websocketd /usr/local/bin/websocketd
    sudo mkdir -p /tmp/tailhist
    sudo tee /root/tailhist.service <<EOF
[Unit]
Description=tailhist

[Install]
WantedBy=multi-user.target

[Service]
WorkingDirectory=/tmp/tailhist
ExecStart=/usr/local/bin/websocketd --port=1088 --staticdir=. sh -c \"tail -n +1 -f /home/$USER_LOGIN/.history || echo 'Could not read history file. Perhaps you need to \\\"chmod +r .history\\\"?'\"
User=nobody
Group=nogroup
Restart=always
EOF
    sudo systemctl enable /root/tailhist.service --now
    "

    pssh -I sudo tee /tmp/tailhist/index.html <lib/tailhist.html
}

_cmd tools "Install a bunch of useful tools (editors, git, jq...)"
_cmd_tools() {
    TAG=$1
    need_tag

    pssh "
    sudo apt-get -q update
    sudo apt-get -qy install apache2-utils emacs-nox git httping htop jid joe jq mosh python-setuptools tree unzip
    # This is for VMs with broken PRNG (symptom: running docker-compose randomly hangs)
    sudo apt-get -qy install haveged
    # I don't remember why we need to remove this
    sudo apt-get remove -y --purge dnsmasq-base
    "
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

    info "If you have manifests hard-coding nodePort values,"
    info "you might want to patch them with a command like:"
    info "

if i_am_first_node; then
    kubectl -n kube-system patch svc prometheus-server \\
        -p 'spec: { ports: [ {port: 80, nodePort: 10101} ]}'
fi

    "
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
    need_login_password
    IP=$(head -1 tags/$TAG/ips.txt)
    info "Logging into $IP (default password: $USER_PASSWORD)"
    ssh $SSHOPTS $USER_LOGIN@$IP

}

_cmd start "Start a group of VMs"
_cmd_start() {
    while [ ! -z "$*" ]; do
        case "$1" in
        --infra) INFRA=$2; shift 2;;
        --settings) SETTINGS=$2; shift 2;;
        --count) die "Flag --count is deprecated; please use --students instead." ;;
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
    echo create_ok > tags/$TAG/status

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
        sep "$TAG -> $step"
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
                info "Step '$step' failed for '$TAG'. Let's wait 10 seconds and try again."
                info "(Attempt $TRY out of $MAXTRY.)"
                sleep 10
            fi
        done
    done
    sep
    info "Deployment successful."
    info "To log into the first machine of that batch, you can run:"
    info "$0 ssh $TAG"
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
    ssh $SSHOPTS -t -L /tmp/tmux-$UID/default:/tmp/tmux-1001/default docker@$IP tmux new-session -As 0
}

_cmd helmprom "Install Prometheus with Helm"
_cmd_helmprom() {
    TAG=$1
    need_tag
    pssh "
    if i_am_first_node; then
        sudo -u $USER_LOGIN -H helm upgrade --install prometheus prometheus \
            --repo https://prometheus-community.github.io/helm-charts/ \
            --namespace prometheus --create-namespace \
            --set server.service.type=NodePort \
            --set server.service.nodePort=30090 \
            --set server.persistentVolume.enabled=false \
            --set alertmanager.enabled=false
    fi"
}

_cmd passwords "Set individual passwords for each cluster"
_cmd_passwords() {
    TAG=$1
    need_tag
    PASSWORDS_FILE="tags/$TAG/passwords"
    if ! [ -f "$PASSWORDS_FILE" ]; then
        error "File $PASSWORDS_FILE not found. Please create it first."
        error "It should contain one password per line."
        error "It should have as many lines as there are clusters."
        die "Aborting."
    fi
    N_CLUSTERS=$($0 ips "$TAG" | wc -l)
    N_PASSWORDS=$(wc -l < "$PASSWORDS_FILE")
    if [ "$N_CLUSTERS" != "$N_PASSWORDS" ]; then
        die "Found $N_CLUSTERS clusters and $N_PASSWORDS passwords. Aborting."
    fi
    $0 ips "$TAG" | paste "$PASSWORDS_FILE" - | while read password nodes; do
        info "Setting password for $nodes..."
        for node in $nodes; do
            echo docker:$password | ssh $SSHOPTS ubuntu@$node sudo chpasswd
        done
    done
    info "Done."
}

_cmd wait "Wait until VMs are ready (reachable and cloud init is done)"
_cmd_wait() {
    TAG=$1
    need_tag

    # Wait until all hosts are reachable.
    info "Trying to reach $TAG instances..."
    while ! pssh -t 5 true 2>&1 >/dev/null; do
        >/dev/stderr echo -n "."
        sleep 2
    done
    >/dev/stderr echo ""

    # If this VM image is using cloud-init,
    # wait for cloud-init to be done
    info "Waiting for cloud-init to be done on $TAG instances..."
    pssh "
    if [ -d /var/lib/cloud ]; then
        while [ ! -f /var/lib/cloud/instance/boot-finished ]; do
            sleep 1
        done
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
    sudo apt-get install python-tornado python-paramiko -y ||
    sudo apt-get install python3-tornado python3-paramiko -y"
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
        sudo docker pull $I
    done'

    info "Finished pulling images for $TAG."
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
            | ssh -A $SSHOPTS $user@$ip sudo -u docker -i \
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
