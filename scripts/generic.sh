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

openvpn --config "${config}" --user user --group user --auth-nocache