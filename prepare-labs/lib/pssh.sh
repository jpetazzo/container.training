# This file can be sourced in order to directly run commands on
# a group of VMs whose IPs are located in ips.txt of the directory in which
# the command is run.

pssh() {
    if [ -z "$TAG" ]; then
        >/dev/stderr echo "Variable \$TAG is not set."
        return
    fi

    if [ "$PSSH_RECORD" ]; then
        pssh_record "$@"
        return
    fi

    # PSSH_HOSTFILE can select a subset of the VMs (e.g. in nodesetup).
    HOSTFILE="${PSSH_HOSTFILE-tags/$TAG/ips.txt}"

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

# Record mode: when $PSSH_RECORD is set to a file name, pssh does not run
# the command. It appends a "run_block" line to that file instead, so that
# the cloudinit command can turn labctl steps into a node setup script.
# The command (and its stdin, for -I) are base64-encoded, to keep them exact.
# Commands for another user (-l root) are not recorded: they are only used
# to fix up cloud images that start with a root login.
pssh_record() {
    local STDIN=""
    while [ $# -gt 0 ]; do
        case "$1" in
            -I) STDIN=yes; shift;;
            -i) shift;;
            -t|--timeout) shift 2;;
            -l) return 1;;
            *) break;;
        esac
    done
    local CMD_B64=$(printf "%s" "$*" | base64 | tr -d '\n')
    local STDIN_B64=-
    if [ "$STDIN" ]; then
        STDIN_B64=$(base64 | tr -d '\n')
        STDIN_B64=${STDIN_B64:--}
    fi
    echo "run_block ${PSSH_RECORD_STEP-unknown} $CMD_B64 $STDIN_B64" >> "$PSSH_RECORD"
}
