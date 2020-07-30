#!/usr/bin/env bash

set -euo pipefail

API="https://api.nordvpn.com/server"
RECOMMENDED_SERVERS="https://nordvpn.com/wp-admin/admin-ajax.php?action=servers_recommendations"
OVPN_FILES="https://downloads.nordcdn.com/configs/archives/servers/ovpn.zip"
PROTCOL="${PROTCOL:-openvpn_udp}"

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

  curl -sSLO "${OVPN_FILES}"
  unzip -q -d "$dest" "ovpn.zip" && \
    f=("$dest"/*) && \
    mv "$dest"/*/*.ovpn "$dest" && \
    rmdir "${f[@]}"
}

echo -n "Downloading configs..."
download_configs "${PWD}/nord"
echo "Done."

servers=$(curl -s "${API}" | jq -c '.[] | select(.features.openvpn_udp == true or .features.openvpn_tcp == true)' | jq -s -a -c 'unique' | jq -c '.[]')

# Filter Server List
IFS=","
if [[ -n "${COUNTRY:-}" ]]; then
  filtered=""
  for cnty in "${COUNTRY[@]}"; do
    filtered+="$(echo "${servers}" | jq -c 'select(.country == "'"${cnty}"'")')"
  done
  servers=$(echo "${filtered}" | jq -s -a -c 'unique' | jq -c '.[]')
fi

if [[ -n "${CATEGORY:-}" ]]; then
  filtered=""
  for cat in "${CATEGORY[@]}"; do
    filtered+="$(echo "${servers}" | jq -c 'select(.categories[].name == "'"${cat}"'")')"
  done
  servers=$(echo "${filtered}" | jq -s -a -c 'unique' | jq -c '.[]')
fi

if [[ -n "${PROTCOL:-}" ]]; then
  filtered=""
  for proto in "${PROTCOL[@]}"; do
    filtered+="$(echo "${servers}" | jq -c 'select(.features.'"${proto}"' == true)')"
  done
  servers=$(echo "${filtered}" | jq -s -a -c 'unique' | jq -c '.[]')
fi

IFS=$'\n'
num_servers="$(echo "${filtered}" | jq -s -a -c 'unique' | jq 'length')"
if [[ -n "${num_servers}" ]]; then
  servers=("$(echo "${servers}" | jq -r '.domain')")
else
  echo "Finding Best Server..."
  servers=("$(curl -s "${RECOMMENDED_SERVERS}" | jq -r '.[] | .hostname' | shuf)")
fi

for server in "${servers[@]}"; do
  case "${PROTCOL:-}" in
    "openvpn_tcp")
      config="./nord/${server}.tcp.ovpn"
      ;;
    "openvpn_udp")
      config="./nord/${server}.udp.ovpn"
      ;;
  esac

  if [ -r "${config:-}" ]; then
    break
  fi
done

[[ -r "${config:-}" ]] || { config="./nord/$(find nord -type f | sed 's|^nord/||' | shuf -n 1)"; }

create_tun

openvpn --config "${config}" \
    --auth-user-pass /dev/shm/auth_file --auth-nocache \
    --user user --group user
