#!/usr/bin/env bash

set -euo pipefail

CONFIGS_URL='https://www.ipvanish.com/software/simpleconf/configs.zip'

IPV="${PWD}/ipvanish"
mkdir -p "${IPV}"
pushd "${IPV}"

curl -sSLO "${CONFIGS_URL}"
unzip -q configs.zip

if [[ -z "${REGION:-}" ]]; then
    echo "REGION must not be empty"
    exit 1
fi

config="$(find . -type f -name "*${REGION}*" | sed 's|\./||' | shuf -n 1)"

if [[ -z "${config}" ]]; then
    echo "Invalid REGION ${REGION}"
    exit 1
fi

sed -i 's|auth-user-pass||' "${config}"

openvpn --config "${config}" \
    --auth-user-pass /dev/shm/auth_file --auth-nocache \
    --user user --group user
