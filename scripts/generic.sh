#!/usr/bin/env bash

set -euo pipefail

if [[ ! -d "/tmp/vpn" ]]; then
    echo "Mount OpenVPN Config in /tmp/vpn/"
    exit 1
fi

config="$(find /tmp/vpn/ -type f -name '*.ovpn')"

if [[ -z "${config}" ]]; then
    echo "No ovpn config found in /tmp/vpn/"
    exit 1
fi

PARAMS="--config ${config} --auth-nocache --user user --group user"

# Use UNAME/PASSWD if they were provided
if [[ ! $(grep -o 'generic' /dev/shm/auth_file) ]]; then
    PARAMS+=" --auth-user-pass /dev/shm/auth_file "
fi
openvpn $PARAMS