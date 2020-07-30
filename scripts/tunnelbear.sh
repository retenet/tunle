#!/usr/bin/env bash

set -euo pipefail

CONFIG_URL="https://s3.amazonaws.com/tunnelbear/linux/openvpn.zip"

TBPATH="${PWD}/tunnelbear"
mkdir -p "${TBPATH}"
pushd "${TBPATH}"

curl -sSLO "${CONFIG_URL}"
unzip -q "openvpn.zip"

if [[ -z "${REGION:-}" ]]; then
    config="$(find "openvpn" -type f -name "*.ovpn" | shuf -n 1)"
else
    config="openvpn/TunnelBear ${REGION}.ovpn"
fi

if [[ ! -r "${config}" ]]; then
    echo "Invalid REGION"
    exit 1
fi

openvpn --config "${config}" \
    --auth-user-pass /dev/shm/auth_file --auth-nocache \
    --user user --group user

