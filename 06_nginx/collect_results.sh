#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

SERVER_IP="192.168.1.104"
DOMAIN_NAME="myapp.test"
HOSTS_ENTRY="${SERVER_IP} ${DOMAIN_NAME}"

echo "Configuring ${DOMAIN_NAME} in /etc/hosts ..."

if grep -Eq "^[[:space:]]*${SERVER_IP//./\\.}[[:space:]]+([^#]*[[:space:]])?${DOMAIN_NAME//./\\.}([[:space:]]|$)" /etc/hosts; then
    echo "The required /etc/hosts entry already exists."
else
    printf '%s\n' "${HOSTS_ENTRY}" | sudo tee -a /etc/hosts >/dev/null
    echo "The required /etc/hosts entry was added."
fi

{
    echo "========================================"
    echo "/etc/hosts on AlmaLinux Controller"
    echo "========================================"
    echo
    echo "Generated at: $(date --iso-8601=seconds)"
    echo
    cat /etc/hosts
} > "${SCRIPT_DIR}/hosts_file.txt"

{
    echo "========================================"
    echo "Nginx Domain Access Test Results"
    echo "========================================"
    echo
    echo "Generated at: $(date --iso-8601=seconds)"
    echo "Server IP: ${SERVER_IP}"
    echo "Domain: ${DOMAIN_NAME}"
    echo

    echo "===== Hosts Resolution Test ====="
    getent hosts "${DOMAIN_NAME}"
    echo

    echo "===== Nginx Health Endpoint ====="
    curl \
        --fail \
        --silent \
        --show-error \
        --include \
        --max-time 15 \
        "http://${DOMAIN_NAME}/nginx-health"
    echo
    echo

    echo "===== Application Through Nginx ====="
    curl \
        --fail \
        --silent \
        --show-error \
        --include \
        --max-time 15 \
        "http://${DOMAIN_NAME}/"
    echo
    echo

    echo "===== HTTP Summary ====="
    curl \
        --fail \
        --silent \
        --show-error \
        --output /dev/null \
        --max-time 15 \
        --write-out 'Resolved IP: %{remote_ip}\nHTTP Status: %{http_code}\nContent Type: %{content_type}\nTotal Time: %{time_total}s\n' \
        "http://${DOMAIN_NAME}/"

    echo
    echo "Final result: PASSED"
} > "${SCRIPT_DIR}/test_results.txt" 2>&1

echo
echo "Generated files:"
echo "  ${SCRIPT_DIR}/hosts_file.txt"
echo "  ${SCRIPT_DIR}/test_results.txt"
