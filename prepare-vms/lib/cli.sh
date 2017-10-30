# Abort if any error happens, and show the command that caused the error.
_ERR() {
    error "Command $BASH_COMMAND failed (exit status: $?)"
}
set -e
trap _ERR ERR

die() {
    if [ -n "$1" ]; then
        error "$1"
    fi
    exit 1
}

error() {
    >/dev/stderr echo "[$(red ERROR)] $1"
}

warning() {
    >/dev/stderr echo "[$(yellow WARNING)] $1"
}

info() {
    >/dev/stderr echo "[$(green INFO)] $1"
}

# Print a full-width separator.
# If given an argument, will print it in the middle of that separator.
# If the argument is longer than the screen width, it will be printed between two separator lines.
sep() {
    if [ -z "$COLUMNS" ]; then
        COLUMNS=80
    fi
    SEP=$(yes = | tr -d "\n" | head -c $(($COLUMNS - 1)))
    if [ -z "$1" ]; then
        >/dev/stderr echo $SEP
    else
        MSGLEN=$(echo "$1" | wc -c)
        if [ $(($MSGLEN + 4)) -gt $COLUMNS ]; then
            >/dev/stderr echo "$SEP"
            >/dev/stderr echo "$1"
            >/dev/stderr echo "$SEP"
        else
            LEFTLEN=$((($COLUMNS - $MSGLEN - 2) / 2))
            RIGHTLEN=$(($COLUMNS - $MSGLEN - 2 - $LEFTLEN))
            LEFTSEP=$(echo $SEP | head -c $LEFTLEN)
            RIGHTSEP=$(echo $SEP | head -c $RIGHTLEN)
            >/dev/stderr echo "$LEFTSEP $1 $RIGHTSEP"
        fi
    fi
}

need_tag() {
    if [ -z "$1" ]; then
        die "Please specify a tag or token. To see available tags and tokens, run: $0 list"
    fi
}

need_settings() {
    if [ -z "$1" ]; then
        die "Please specify a settings file."
    elif [ ! -f "$1" ]; then
        die "Settings file $1 doesn't exist."
    fi
}

need_ips_file() {
    IPS_FILE=$1
    if [ -z "$IPS_FILE" ]; then
        die "IPS_FILE not set."
    fi

    if [ ! -s "$IPS_FILE" ]; then
        die "IPS_FILE $IPS_FILE not found. Please run: $0 ips <TAG>"
    fi
}
