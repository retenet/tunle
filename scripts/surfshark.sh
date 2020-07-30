#!/usr/bin/env bash

set -euo pipefail

CONFIG_URL="https://account.surfshark.com/api/v1/server/configurations"

SSPATH="${PWD}/surfshark"
mkdir -p "${SSPATH}"
pushd "${SSPATH}"

curl -sSLO "${CONFIG_URL}"
unzip -q "configurations"

PROTOCOL="${PROTOCOL:-udp}"

if [[ "${PROTOCOL}" != "tcp" && "${PROTOCOL}" != "udp" ]]; then
    echo "Invalid PROTOCOL"
    exit 1
fi


if [[ -z "${REGION:-}" ]]; then
    config="$(find . -type f -name "*_${PROTOCOL}.ovpn" | sed 's|\./||' | shuf -n 1)"
else
    config="$(find . -type f -name "*_${PROTOCOL}.ovpn" | sed 's|\./||' | grep -i "${REGION}" | shuf -n 1)"
fi

if [[ ! -r "${config}" ]]; then
    echo "Invalid REGION"
    exit 1
fi

openvpn --config "${config}" \
    --auth-user-pass /dev/shm/auth_file --auth-nocache \
    --user user --group user

