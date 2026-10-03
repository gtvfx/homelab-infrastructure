#!/usr/bin/env bash

set -euo pipefail

ADMIN_USER="${ADMIN_USER:-labadmin}"
RUNNER_USER="${RUNNER_USER:-runner}"
REPOSITORY_URL="${REPOSITORY_URL:-https://github.com/gtvfx/homelab-infrastructure.git}"
REPOSITORY_BRANCH="${REPOSITORY_BRANCH:-main}"
REPOSITORY_DIRECTORY="${REPOSITORY_DIRECTORY:-/opt/homelab-infrastructure}"

if [[ $EUID -ne 0 ]]; then
    printf 'Run this script as root.\n' >&2
    exit 1
fi

if ! getent passwd "$ADMIN_USER" >/dev/null; then
    printf 'Administrative account does not exist: %s\n' "$ADMIN_USER" >&2
    exit 1
fi

printf 'Installing host bootstrap prerequisites...\n'
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ca-certificates \
    git \
    sudo

if ! getent passwd "$RUNNER_USER" >/dev/null; then
    printf 'Creating dedicated runner account: %s\n' "$RUNNER_USER"
    useradd --create-home --shell /bin/bash "$RUNNER_USER"
fi

runner_home="$(getent passwd "$RUNNER_USER" | cut -d: -f6)"
runner_group="$(id -gn "$RUNNER_USER")"

passwd --lock "$RUNNER_USER" >/dev/null
install -d -o "$RUNNER_USER" -g "$runner_group" -m 0700 "$runner_home"
install -d -o "$RUNNER_USER" -g "$runner_group" \
    "$runner_home/actions-runner"

if id -nG "$RUNNER_USER" | tr ' ' '\n' | grep -Fxq sudo; then
    printf 'Runner account must not belong to the sudo group.\n' >&2
    exit 1
fi

if [[ -d $REPOSITORY_DIRECTORY/.git ]]; then
    configured_url="$(git -C "$REPOSITORY_DIRECTORY" remote get-url origin)"
    if [[ $configured_url != "$REPOSITORY_URL" ]]; then
        printf 'Unexpected repository origin: %s\n' "$configured_url" >&2
        exit 1
    fi

    printf 'Updating infrastructure checkout...\n'
    git -C "$REPOSITORY_DIRECTORY" checkout "$REPOSITORY_BRANCH"
    git -C "$REPOSITORY_DIRECTORY" pull --ff-only origin "$REPOSITORY_BRANCH"
elif [[ -e $REPOSITORY_DIRECTORY ]]; then
    printf 'Repository path exists but is not a Git checkout: %s\n' \
        "$REPOSITORY_DIRECTORY" >&2
    exit 1
else
    printf 'Cloning infrastructure repository...\n'
    git clone --branch "$REPOSITORY_BRANCH" --single-branch \
        "$REPOSITORY_URL" "$REPOSITORY_DIRECTORY"
fi

chown -R root:root "$REPOSITORY_DIRECTORY"

sudoers_source="$REPOSITORY_DIRECTORY/runners/linux/sudoers.d/labadmin-runner-provision"
sudoers_target="/etc/sudoers.d/labadmin-runner-provision"

install -o root -g root -m 0440 "$sudoers_source" "$sudoers_target"
visudo -cf "$sudoers_target"

bash "$REPOSITORY_DIRECTORY/runners/linux/provision-build-tools.sh"

printf 'Runner host bootstrap completed. GitHub registration remains separate.\n'
