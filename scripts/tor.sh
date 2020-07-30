#!/usr/bin/env bash

set -euo pipefail

echo -n "Loading Configuration..."

cat <<EOT > /etc/tor/torrc
VirtualAddrNetworkIPv4 10.192.0.0/10
VirtualAddrNetworkIPv6 [fc00::]/7
AutomapHostsOnResolve 1
TransPort 0.0.0.0:9040 IsolateClientAddr IsolateClientProtocol IsolateDestAddr IsolateDestPort
TransPort [::]:9040 IsolateClientAddr IsolateClientProtocol IsolateDestAddr IsolateDestPort
DNSPort 0.0.0.0:5353
DNSPort [::]:5353

ServerDNSDetectHijacking 0
EOT

echo "Done."

echo "Starting Tor..."
su user -c "tor"
