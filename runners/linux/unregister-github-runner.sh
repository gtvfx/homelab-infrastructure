#!/usr/bin/env bash

set -euo pipefail

RUNNER_USER="${RUNNER_USER:-runner}"
RUNNER_ROOT="${RUNNER_ROOT:-}"

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

if [[ ! -e $RUNNER_ROOT/.runner ]]; then
    printf 'Runner is not registered.\n' >&2
    exit 1
fi

if [[ -z ${RUNNER_TOKEN:-} ]]; then
    printf 'Provide a short-lived GitHub removal token in RUNNER_TOKEN.\n' >&2
    exit 1
fi

if [[ -x $RUNNER_ROOT/svc.sh ]]; then
    (
        cd "$RUNNER_ROOT"
        ./svc.sh stop || true
        ./svc.sh uninstall || true
    )
fi

runuser -u "$RUNNER_USER" -- bash -c \
    'cd "$1"; shift; exec ./config.sh "$@"' \
    _ "$RUNNER_ROOT" remove \
    --token "$RUNNER_TOKEN"
unset RUNNER_TOKEN

printf 'GitHub Actions runner service and registration removed.\n'
