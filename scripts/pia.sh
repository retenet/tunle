#!/usr/bin/env bash

set -euo pipefail
[[ -n ${DEBUG:-} ]] && set -x

MAN_VER="v1.1.0"
export MAX_LATENCY=${MAX_LATENCY:-0.05}
PROTOCOL=${PROTOCOL:-udp}
ENCRYPTION=${ENCRYPTION:-strong}
export PIA_DNS=${PIA_DNS:-true}
export PIA_FP=${PIA_FP:-}

create_tun() {
  mkdir -p /dev/net
  [[ -c /dev/net/tun ]] || mknod -m 0666 /dev/net/tun c 10 200
}

create_tun
curl -sSL -o - "https://github.com/pia-foss/manual-connections/archive/${MAN_VER}.tar.gz" | tar zxv --strip 1

# We don't want the vpn to be daemonized
sed -i 's:\-\-daemon::' connect_to_openvpn_with_token.sh

if [[ -f /proc/net/if_inet6 ]] &&
  [[ $(sysctl -n net.ipv6.conf.all.disable_ipv6) -ne 1 ||
     $(sysctl -n net.ipv6.conf.default.disable_ipv6) -ne 1 ]]
then
  echo 'Disabling IPv6...'
  sysctl -w net.ipv6.conf.all.disable_ipv6=1
  sysctl -w net.ipv6.conf.default.disable_ipv6=1
fi

case "$VPN_TYPE" in 
    "openvpn")
        PIA_AUTOCONNECT="openvpn_${PROTOCOL}_${ENCRYPTION}"
        ;;
    "wireguard")
        PIA_AUTOCONNECT="wireguard"
        ;;
    *)
        echo "Invalid VPN_TYPE [openvpn, wireguard]"
        exit 1
        ;;
esac

export PIA_USER="${UNAME}"
export PIA_PASS="${PASSWD}"
export PIA_AUTOCONNECT

/bin/bash get_region_and_token.sh

sleep infinity &
wait $!
