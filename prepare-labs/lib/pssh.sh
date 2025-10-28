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

    # There are some routers that really struggle with the number of TCP
    # connections that we open when deploying large fleets of clusters.
    # We're adding a 1 second delay here, but this can be cranked up if
    # necessary - or down to zero, too.
    sleep ${PSSH_DELAY_PRE-1}

    # When things go wrong, it's convenient to ask pssh to show the output
    # of the failed command. Let's make that easy with a DEBUG env var.
    if [ "$DEBUG" ]; then
        PSSH_I=-i
    else
        PSSH_I=""
    fi

    $(which pssh || which parallel-ssh) -h $HOSTFILE -l ubuntu \
        --par ${PSSH_PARALLEL_CONNECTIONS-100} \
        --timeout 300 \
        -O LogLevel=ERROR \
        -O IdentityFile=tags/$TAG/id_rsa \
        -O UserKnownHostsFile=/dev/null \
        -O StrictHostKeyChecking=no \
        -O ForwardAgent=yes \
        $PSSH_I \
        "$@"
}
