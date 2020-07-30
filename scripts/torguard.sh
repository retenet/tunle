#!/usr/bin/env bash

set -euo pipefail

PROTOCOL="${PROTOCOL:-udp}"

if [[ "${PROTOCOL}" != "tcp" && "${PROTOCOL}" != "udp" ]]; then
    echo "Invalid Protocol"
    exit 1
fi

PROTOCOL="${PROTOCOL^^}"
CONFIG_ZIP="OpenVPN-${PROTOCOL}-Standard.zip"
CONFIG_URL="https://torguard.net/downloads/${CONFIG_ZIP}"

TGPATH="${PWD}/torguard"
mkdir -p "${TGPATH}"
pushd "${TGPATH}"

curl -sSLO "${CONFIG_URL}"
unzip -q "${CONFIG_ZIP}"

REGION="${REGION// /.}"

if [[ -z "${REGION:-}" ]]; then
    config="$(find "OpenVPN-${PROTOCOL}" -type f -name "*.ovpn" | shuf -n 1)"
else
    config="OpenVPN-${PROTOCOL}/TorGuard.${REGION}.ovpn"
fi

if [[ ! -r "${config}" ]]; then
    echo "Invalid REGION"
    exit 1
fi

openvpn --config "${config}" \
    --auth-user-pass /dev/shm/auth_file --auth-nocache \
    --user user --group user
