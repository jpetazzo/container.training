# This file can be sourced in order to directly run commands on
# a group of VMs whose IPs are located in ips.txt of the directory in which
# the command is run.

pssh() {
    if [ -z "$TAG" ]; then
        >/dev/stderr echo "Variable \$TAG is not set."
        return
    fi

    HOSTFILE="tags/$TAG/ips.txt"

    [ -f $HOSTFILE ] || {
        >/dev/stderr echo "Hostfile $HOSTFILE not found."
        return
    }

    echo "[parallel-ssh] $@"

    $(which pssh || which parallel-ssh) -h $HOSTFILE -l ubuntu \
        --par ${PSSH_PARALLEL_CONNECTIONS-100} \
        --timeout 300 \
        -O LogLevel=ERROR \
        -O IdentityFile=tags/$TAG/id_rsa \
        -O UserKnownHostsFile=/dev/null \
        -O StrictHostKeyChecking=no \
        -O ForwardAgent=yes \
        "$@"
}
