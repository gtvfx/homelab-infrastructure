#!/usr/bin/env bash

set -euo pipefail

RUNNER_USER="${RUNNER_USER:-runner}"
RUNNER_VERSION="${RUNNER_VERSION:-2.337.0}"
RUNNER_SHA256="${RUNNER_SHA256:-70920811a4f8ad4328818682bca5c6469c1c942fab52448868071d0063816613}"
RUNNER_ROOT="${RUNNER_ROOT:-}"

if [[ $EUID -ne 0 ]]; then
    printf 'Run this script as root.\n' >&2
    exit 1
fi

if [[ $(uname -m) != x86_64 ]]; then
    printf 'This installer currently supports only Linux x86-64.\n' >&2
    exit 1
fi

if ! getent passwd "$RUNNER_USER" >/dev/null; then
    printf 'Runner account does not exist: %s\n' "$RUNNER_USER" >&2
    exit 1
fi

runner_home="$(getent passwd "$RUNNER_USER" | cut -d: -f6)"
runner_group="$(id -gn "$RUNNER_USER")"

if [[ -z $RUNNER_ROOT ]]; then
    RUNNER_ROOT="$runner_home/actions-runner"
fi

if [[ -e $RUNNER_ROOT/.runner || -e $RUNNER_ROOT/.credentials || \
    -e $RUNNER_ROOT/.credentials_rsaparams ]]; then
    printf 'Refusing to modify an already registered runner.\n' >&2
    exit 1
fi

listener="$RUNNER_ROOT/bin/Runner.Listener"
if [[ -x $listener ]]; then
    installed_version="$(runuser -u "$RUNNER_USER" -- "$listener" --version)"
    if [[ $installed_version == "$RUNNER_VERSION" ]]; then
        printf 'GitHub Actions runner %s is already installed.\n' "$RUNNER_VERSION"
        exit 0
    fi

    printf 'A different runner version is already installed: %s\n' \
        "$installed_version" >&2
    exit 1
fi

unexpected_entry="$(
    find "$RUNNER_ROOT" -mindepth 1 -maxdepth 1 ! -name _work -print -quit
)"
if [[ -n $unexpected_entry ]]; then
    printf 'Runner directory contains unexpected content: %s\n' \
        "$unexpected_entry" >&2
    exit 1
fi

printf 'Installing runner download prerequisites...\n'
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ca-certificates \
    curl \
    gzip \
    tar

archive_name="actions-runner-linux-x64-$RUNNER_VERSION.tar.gz"
download_url="https://github.com/actions/runner/releases/download/v$RUNNER_VERSION/$archive_name"
temporary_directory="$(mktemp -d)"
archive_path="$temporary_directory/$archive_name"
trap 'rm -rf "$temporary_directory"' EXIT

printf 'Downloading GitHub Actions runner %s...\n' "$RUNNER_VERSION"
curl --fail --location --proto '=https' --tlsv1.2 \
    --output "$archive_path" "$download_url"

printf '%s  %s\n' "$RUNNER_SHA256" "$archive_path" | sha256sum --check

install -d -o "$RUNNER_USER" -g "$runner_group" "$RUNNER_ROOT"
tar -xzf "$archive_path" -C "$RUNNER_ROOT"
chown -R "$RUNNER_USER:$runner_group" "$RUNNER_ROOT"

printf 'Installing runner runtime dependencies...\n'
bash "$RUNNER_ROOT/bin/installdependencies.sh"

installed_version="$(runuser -u "$RUNNER_USER" -- "$listener" --version)"
if [[ $installed_version != "$RUNNER_VERSION" ]]; then
    printf 'Unexpected installed runner version: %s\n' "$installed_version" >&2
    exit 1
fi

printf 'GitHub Actions runner %s installed without registration.\n' \
    "$installed_version"
