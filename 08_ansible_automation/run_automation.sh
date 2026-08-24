#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
ANSIBLE_DIR="${PROJECT_ROOT}/02_ansible_setup"

cd "${ANSIBLE_DIR}"

ansible-galaxy collection install \
  -r "${SCRIPT_DIR}/requirements.yml"

ansible-playbook \
  -i inventory \
  "${SCRIPT_DIR}/site.yml" \
  --ask-become-pass \
  -v \
  2>&1 | tee "${SCRIPT_DIR}/playbook_output.txt"

echo
echo "Generated files:"
echo "  ${SCRIPT_DIR}/playbook_output.txt"
echo "  ${SCRIPT_DIR}/verification.txt"
