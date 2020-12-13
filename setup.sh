#!/usr/bin/env bash

set -euo pipefail

[[ -n ${DEBUG:-} ]] && set -x

# Intialize variables
PROVIDER="${PROVIDER:-generic}"
VPN_TYPE="${VPN_TYPE:-openvpn}"

isfile() {
  if [[ -r "${1:-}" ]]; then
      true
      return
  fi
  false
  return
}

# Check for CAP_NET_ADMIN and CAP_NET_RAW
if ! iptables -nL >/dev/null 2>&1; then
  >&2 echo "Container requires CAP_NET_ADMIN and CAP_NET_RAW," \
      "add using '--cap-add=NET_ADMIN --cap-add=NET_RAW'."
  exit 1
fi

# Check for a valid Provider
case "${PROVIDER}" in

  "cyberghost")
    echo "Loading CyberGhost..."
    ;;

  "generic")
    echo "Loading Generic $VPN_TYPE..."
    UNAME="generic"
    PASSWD="generic"
    ;;
    
  "ipvanish")
    echo "Loading IPVanish..."
    ;;

  "nord")
    echo "Loading NordVPN..."
    ;;

  "pia")
    echo "Loading Private Internet Access..."
    ;;

  "surfshark")
    echo "Loading SurfShark..."
    ;;

  "tor")
    echo "Loading Tor Network Proxy..."
    ;;

  "torguard")
    echo "Loading TorGuard..."
    ;;

  "tunnelbear")
    echo "Loading TunnelBear..."
    ;;

  *)
    echo "Invalid Provider"
    exit 1
    ;;
esac

# Set Location of iptables File
IPV4_FPATH="./iptables/v4/${PROVIDER}"
IPV6_FPATH="./iptables/v6/${PROVIDER}"

# Double check to make sure file exists
if isfile "${IPV4_FPATH}" && isfile "${IPV6_FPATH}"; then
  iptables-restore "${IPV4_FPATH}" || {
    echo "Error Loading IPv4 iptables"; 
    exit 1
  }

  # Check for IPV6 Support
  if test -f /proc/net/if_inet6; then
    ip6tables-restore "${IPV6_FPATH:-./iptables/v6/block_all}" >/dev/null 2>&1 || echo "modprobe ip6table_filter for IPv6 Support."
  fi
else
  echo "Invalid iptables file [${IPV4_FPATH}, ${IPV6_FPATH}]"
  exit 1
fi

# Check if Username and Password are Populated
if [ "${PROVIDER}" != "tor" ]; then
    if [[ -z ${UNAME:-} ||  -z ${PASSWD:-} ]]; then 
      printf "%s\n" "Missing Username or Password"; 
      exit 1; 
    else
      rm -f /dev/shm/auth_file
      cat <<EOT > /dev/shm/auth_file
    $UNAME
    $PASSWD
EOT
      chmod 0600 /dev/shm/auth_file
    fi
fi

# Cloudflare DNS
# TODO: DoT over VPN
echo 'nameserver 1.1.1.1' > /etc/resolv.conf

# Load Provider
spath="./scripts/${PROVIDER}.sh"
if [ -r "${spath}" ]; then
  # shellcheck source=/dev/null
  /bin/bash "${spath}"
fi
