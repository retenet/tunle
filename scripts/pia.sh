#!/usr/bin/env bash

set -euo pipefail

OVPN_FILES="https://www.privateinternetaccess.com/openvpn/openvpn"

create_tun() {
  mkdir -p /dev/net
  [[ -c /dev/net/tun ]] || mknod -m 0666 /dev/net/tun c 10 200
}

download_configs() {
  local dest
  dest="$1"
  if [[ -d "$dest"  ]]; then
      return
  fi

  curl -sSL "${OVPN_FILES}" -o ovpn.zip
  unzip -q -d "$dest" "ovpn.zip"
}

case "${ENCRYPTION:-normal}" in
    # do nothing
    "normal")
      ;;

    "strong")
      OVPN_FILES+="-strong"
      ;;

    *)
      echo "Invalid Encryption"
      exit 1
      ;;
esac

case "${PROTCOL:-udp}" in
    "udp")
      OVPN_FILES+=".zip"
      ;;
    "tcp")
      OVPN_FILES+="-tcp.zip"
      ;;
    *)
      echo "Invalid Protocol"
      exit 1
      ;;
esac

echo -n "Downloading configs..."
download_configs "${PWD}/pia"
echo "Done."

if [[ -n "${REGION:-}" ]]; then
    config="${PWD}/pia/${REGION}.ovpn"
fi

[[ -r "${config:-}" ]] || { config="./pia/$(find pia -type f | sed 's|^pia/||' | shuf -n 1)"; }

openvpn --config "${config}" \
    --auth-user-pass /dev/shm/auth_file --auth-nocache \
    --user user --group user
