#!/bin/sh

[ -z "$2" ] && {
	echo "Syntax: $0 <host> <command>"
        echo "
Command should be:
  connect     Cancels the effects of 'disconnect'
  disconnect  Disable all network communication except SSH
  reboot      Sync disks and immediately reboot (without proper shutdown)
"
	exit 1
}

ssh docker@$1 sudo sh <<EOF
_cm_init () {
        iptables -L CHAOSMONKEY >/dev/null 2>/dev/null || {
                iptables -N CHAOSMONKEY
                iptables -I FORWARD -j CHAOSMONKEY
                iptables -I INPUT -j CHAOSMONKEY
                iptables -I OUTPUT -j CHAOSMONKEY
        }
}

_cm_reboot () {
        echo "Rebooting..."
        echo s > /proc/sysrq-trigger
        echo u > /proc/sysrq-trigger
        echo b > /proc/sysrq-trigger
}

_cm_disconnect () {
        _cm_init
        echo "Dropping all network traffic, except SSH..."
        iptables -F CHAOSMONKEY
        iptables -A CHAOSMONKEY -p tcp --sport 22 -j ACCEPT
        iptables -A CHAOSMONKEY -p tcp --dport 22 -j ACCEPT
        iptables -A CHAOSMONKEY -j DROP
}

_cm_connect () {
        _cm_init
        echo "Re-enabling network communication..."
        iptables -F CHAOSMONKEY
}

_cm_$2
EOF
