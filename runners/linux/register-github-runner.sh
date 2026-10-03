#!/usr/bin/env bash

set -euo pipefail

RUNNER_USER="${RUNNER_USER:-runner}"
RUNNER_ROOT="${RUNNER_ROOT:-}"
RUNNER_NAME="${RUNNER_NAME:-$(hostname --short)}"
RUNNER_GROUP="${RUNNER_GROUP:-trusted-ci}"
RUNNER_LABELS="${RUNNER_LABELS:-debian-13,ci}"
RUNNER_WORK_DIRECTORY="${RUNNER_WORK_DIRECTORY:-_work}"
RUNNER_DISABLE_DEFAULT_LABELS="${RUNNER_DISABLE_DEFAULT_LABELS:-0}"
GITHUB_URL="${GITHUB_URL:-https://github.com/gtvfx-envoy}"

if [[ $EUID -ne 0 ]]; then
    printf 'Run this script as root.\n' >&2
    exit 1
fi

if ! getent passwd "$RUNNER_USER" >/dev/null; then
    printf 'Runner account does not exist: %s\n' "$RUNNER_USER" >&2
    exit 1
fi

runner_home="$(getent passwd "$RUNNER_USER" | cut -d: -f6)"

if [[ -z $RUNNER_ROOT ]]; then
    RUNNER_ROOT="$runner_home/actions-runner"
fi

if [[ ! -x $RUNNER_ROOT/config.sh ]]; then
    printf 'Install the GitHub Actions runner before registration.\n' >&2
    exit 1
fi

if [[ -e $RUNNER_ROOT/.runner || -e $RUNNER_ROOT/.credentials || \
    -e $RUNNER_ROOT/.credentials_rsaparams ]]; then
    printf 'Refusing to overwrite an existing runner registration.\n' >&2
    exit 1
fi

if [[ -z ${RUNNER_TOKEN:-} ]]; then
    if ! IFS= read -r RUNNER_TOKEN || [[ -z $RUNNER_TOKEN ]]; then
        printf 'Provide a short-lived token through standard input or RUNNER_TOKEN.\n' >&2
        exit 1
    fi
fi

config_arguments=(
    --unattended
    --url "$GITHUB_URL"
    --token "$RUNNER_TOKEN"
    --name "$RUNNER_NAME"
    --runnergroup "$RUNNER_GROUP"
    --labels "$RUNNER_LABELS"
    --work "$RUNNER_WORK_DIRECTORY"
)

if [[ $RUNNER_DISABLE_DEFAULT_LABELS == 1 ]]; then
    config_arguments+=(--no-default-labels)
fi

printf 'Registering runner %s with %s...\n' "$RUNNER_NAME" "$GITHUB_URL"
(
    cd "$RUNNER_ROOT"
    runuser -u "$RUNNER_USER" -- ./config.sh "${config_arguments[@]}"
)
unset RUNNER_TOKEN

if [[ ! -x $RUNNER_ROOT/svc.sh ]]; then
    printf 'Registration completed without creating the service helper.\n' >&2
    exit 1
fi

(
    cd "$RUNNER_ROOT"
    ./svc.sh install "$RUNNER_USER"
    ./svc.sh start
    ./svc.sh status
)

printf 'GitHub Actions runner registration completed.\n'
