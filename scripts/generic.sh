#!/usr/bin/env bash

set -euo pipefail

finish(){
    wg-quick down "$1"
    exit 0
}

_wireguard(){
    if [[ ! -d "/etc/wireguard/" ]]; then
        echo "Mount Wireguard Config in /etc/wireguard/"
        exit 1
    fi

    config="$(find /etc/wireguard/ -type f -name '*.conf')"

    if [[ -z "${config}" ]]; then
        echo "No *.conf config found in /etc/wireguard/"
        exit 1
    fi

    # shellcheck disable=SC2064
    trap "finish $config" SIGTERM SIGINT SIGQUIT

    wg-quick up "$config"

    sleep infinity &
    wait $!
}

_openvpn(){
    if [[ ! -d "/tmp/vpn" ]]; then
        echo "Mount OpenVPN Config in /tmp/vpn/"
        exit 1
    fi
    
    config="$(find /tmp/vpn/ -type f -name '*.ovpn')"
    
    if [[ -z "${config}" ]]; then
        echo "No *.ovpn config found in /tmp/vpn/"
        exit 1
    fi
    
    PARAMS="--config ${config} --auth-nocache --user user --group user"
    
    # Use UNAME/PASSWD if they were provided
    # shellcheck disable=SC2143
    if [[ ! $(grep -qo 'generic' /dev/shm/auth_file) ]]; then
        PARAMS+=" --auth-user-pass /dev/shm/auth_file "
    fi
    openvpn "$PARAMS"
}

case "$VPN_TYPE" in 
    "openvpn")
        _openvpn
        ;;
    "wireguard")
        _wireguard
        ;;
    *)
        echo "Invalid VPN_TYPE [openvpn, wireguard]"
        exit 1
        ;;
esac