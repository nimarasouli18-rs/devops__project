#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

cd "${PROJECT_ROOT}"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "ERROR: ${PROJECT_ROOT} is not a Git repository." >&2
    echo "Run 'git init' and create the meaningful commits first." >&2
    exit 1
fi

mkdir -p "${SCRIPT_DIR}"

{
    echo "========================================"
    echo "Git History"
    echo "========================================"
    echo
    echo "Generated at: $(date --iso-8601=seconds)"
    echo
    git log \
        --oneline \
        --graph \
        --decorate \
        --all
} > "${SCRIPT_DIR}/git_history.txt"

{
    echo "========================================"
    echo "Final Project Structure"
    echo "========================================"
    echo
    echo "Generated at: $(date --iso-8601=seconds)"
    echo
    echo "Excluded from this report:"
    echo "- .git metadata"
    echo "- external clone: 03_project_clone/awesome-compose"
    echo "- runtime .env files"
    echo "- database password files"
    echo "- private certificate material"
    echo

    if command -v tree >/dev/null 2>&1; then
        tree \
            -a \
            -I '.git|awesome-compose|.env|db_password.txt|certificates|__pycache__|*.pyc|*.pyo|.pytest_cache|.venv' \
            .
    else
        find . \
            \( \
                -path './.git' \
                -o -path './03_project_clone/awesome-compose' \
                -o -path '*/.env' \
                -o -path '*/secrets/db_password.txt' \
                -o -path '*/certificates' \
                -o -path '*/__pycache__' \
            \) -prune \
            -o -print |
        sort
    fi
} > "${SCRIPT_DIR}/final_structure.txt"

echo "Generated:"
echo "  ${SCRIPT_DIR}/git_history.txt"
echo "  ${SCRIPT_DIR}/final_structure.txt"
