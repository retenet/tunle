#!/usr/bin/env bash

set -euo pipefail

# Windows V1 API
BASE_URL="https://api.cyberghostvpn.com/cg"
CONSUMER_KEY="45d3fdd1635601b1c28a3d2f1d78d83e1c7edbb4"
CONSUMER_SECRET="b97627f1c114d6b5eb567aa70b956001da3e5eea"

AUTH_HEADER="OAuth realm=\"api.cyberghostvpn.com\",\
oauth_version=\"1.0\",\
oauth_signature_method=\"PLAINTEXT\",\
oauth_consumer_key=\"${CONSUMER_KEY}\",\
oauth_signature=\"${CONSUMER_SECRET}%26\""

REGION="${REGION:-}"
CG_DIR="${PWD}/cyberghost"

authenticate() {
    local URI res
    reset=${1:-}

    URI="/oauth/access_token?hid=F3C2-9235-7BB7-458D-34E2-5117-C8C0-10C7${reset}"
    res="$(curl -sSL "${BASE_URL}${URI}" \
        -X POST \
        -A 'CG7Win' \
        -H "Authorization: ${AUTH_HEADER}" \
        -H 'Content-Type: application/json' \
        -d "{\"x_auth_username\":\"${UNAME:-}\",\
             \"x_auth_password\":\"${PASSWD:-}\",\
             \"x_auth_mode\":\"client_auth\"}"
    )"

    if [[ "${res}" == *"MAXIMUM ACTIVATIONS REACHED"* ]]; then
        echo "Maximum number of Devices allocated."
        echo "Resetting Devices..."
        authenticate "&reset=1"
        return
    fi

    eval "$(echo "$res" | awk -F'&' '{print $1}')"
    export oauth_token

    eval "$(echo "$res" | awk -F'&' '{print $2}')"
    export oauth_token_secret
}

get_status() {
    local URI res

    URI='/status'
    res="$(curl -sSL "${BASE_URL}${URI}" \
        -A 'CG7Win' \
        -H "Authorization: ${AUTH_HEADER}" \
        -H 'Content-Type: application/json' \
    )"


    echo "${res}" | jq
}

get_user() {
    local URI res username password
    
    URI="/users/me?flags=18"
    res="$(curl -sSL "${BASE_URL}${URI}" \
        -A 'CG7Win' \
        -H "Authorization: ${AUTH_HEADER}" \
        -H 'Content-Type: application/json' \
    )"

    # echo "${res}" | jq -c

    username="$(echo "${res}" | jq -c '.user_name'| tr -d '\"')"
    password="$(echo "${res}" | jq -c '.temp_psw' | tr -d '\"')"
    cat <<EOT > auth_file
$username
$password
EOT
    chmod 0600 auth_file
}

get_servers() {
    local URI res

    if [[ -n "${1:-}" ]]; then
        COUNTRY="country=${1}"
    fi

    URI="/servers/?flags=16&filter=74&${COUNTRY}&exclude=&filter_protocol=OPENVPN"
    res="$(curl -sSL "${BASE_URL}${URI}" \
        -A 'CG7Win' \
        -H "Authorization: ${AUTH_HEADER}" \
        -H 'Content-Type: application/json' \
    )"

    # Pick a random server from the list
    SERVER="$(echo "${res}" | jq -c '.[] | .name' | shuf -n 1 | tr -d '\"')"

}

get_ca() {
    local URI res

    URI="/certificate/ca?flags=0&lang=en&rid=78&hid=F3C2-9235-7BB7-458D-34E2-5117-C8C0-10C7"
    res="$(curl -sSL "${BASE_URL}${URI}" \
        -A 'CG7Win' \
        -H "Authorization: ${AUTH_HEADER}" \
        -H 'Content-Type: application/json' \
    )"

    echo "${res}" | jq -c '.ca' | xargs echo -e > ca.crt
}

if [[ ${#REGION} -ne 2 ]]; then
    echo "REGION must be the ISO Country Code."
    exit 1
fi

mkdir -p "${CG_DIR}"
pushd "${CG_DIR}"

if [[ -z "${oauth_token:-}" && -z "${oauth_token_secret:-}" ]]; then
    authenticate
fi

# Update Header with Oauth Tokens
AUTH_HEADER="OAuth realm=\"api.cyberghostvpn.com\",\
oauth_version=\"1.0\",\
oauth_signature_method=\"PLAINTEXT\",\
oauth_consumer_key=\"${CONSUMER_KEY}\",\
oauth_token=\"${oauth_token}\",\
oauth_signature=\"${CONSUMER_SECRET}%26${oauth_token_secret}\""

get_ca
get_user
get_servers "${REGION}"

cat <<EOT > openvpn.ovpn
client
remote ${SERVER}.cg-dialup.net 443
dev tun 
proto udp
auth-user-pass auth_file

auth-nocache
mute-replay-warnings
auth-retry nointeract
pull-filter ignore "auth-token"

resolv-retry infinite 
redirect-gateway def1
persist-key
persist-tun
nobind
cipher AES-256-CBC
ncp-disable
auth SHA256
ping 5
ping-exit 60
ping-timer-rem
explicit-exit-notify 2
script-security 2
remote-cert-tls server
route-delay 5
verb 4

user user
group user

ca ca.crt
EOT

openvpn openvpn.ovpn
