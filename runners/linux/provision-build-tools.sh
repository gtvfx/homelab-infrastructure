#!/usr/bin/env bash

set -euo pipefail

UV_VERSION="${UV_VERSION:-0.12.22}"
PYTHON_VERSION="${PYTHON_VERSION:-3.11.9}"
RUNNER_USER="${RUNNER_USER:-runner}"
RUNNER_ROOT="${RUNNER_ROOT:-}"
RUNNER_TOOL_CACHE="${RUNNER_TOOL_CACHE:-}"

if [[ $EUID -ne 0 ]]; then
    printf 'Run this script as root.\n' >&2
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

if [[ -z $RUNNER_TOOL_CACHE ]]; then
    RUNNER_TOOL_CACHE="$RUNNER_ROOT/_work/_tool"
fi

uv_install_directory="$runner_home/.local/bin"
uv_binary="$uv_install_directory/uv"
python_minor="${PYTHON_VERSION%.*}"
python_cache_directory="$RUNNER_TOOL_CACHE/Python/$PYTHON_VERSION"
python_cache_link="$python_cache_directory/x64"
python_cache_marker="$python_cache_directory/x64.complete"

printf 'Installing Debian build prerequisites...\n'
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential \
    ca-certificates \
    curl

install -d -o "$RUNNER_USER" -g "$runner_group" "$uv_install_directory"

if [[ ! -x $uv_binary ]] || ! "$uv_binary" --version | grep -Fq "$UV_VERSION"; then
    printf 'Installing uv %s for %s...\n' "$UV_VERSION" "$RUNNER_USER"
    runuser -u "$RUNNER_USER" -- env \
        HOME="$runner_home" \
        UV_INSTALL_DIR="$uv_install_directory" \
        UV_NO_MODIFY_PATH=1 \
        bash -c \
        "cd \"\$HOME\" && curl -LsSf https://astral.sh/uv/$UV_VERSION/install.sh | sh"
fi

printf 'Installing Python %s for %s...\n' "$PYTHON_VERSION" "$RUNNER_USER"
runuser -u "$RUNNER_USER" -- env HOME="$runner_home" \
    bash -c 'cd "$HOME" && exec "$1" python install "$2"' \
    _ "$uv_binary" "$PYTHON_VERSION"

python_executable="$(
    runuser -u "$RUNNER_USER" -- env HOME="$runner_home" \
        bash -c 'cd "$HOME" && exec "$1" python find "$2"' \
        _ "$uv_binary" "$PYTHON_VERSION"
)"
python_prefix="$(dirname "$(dirname "$python_executable")")"

install -d -o "$RUNNER_USER" -g "$runner_group" "$python_cache_directory"

if [[ -e $python_cache_link || -L $python_cache_link ]]; then
    existing_target="$(readlink -f "$python_cache_link")"
    expected_target="$(readlink -f "$python_prefix")"
    if [[ $existing_target != "$expected_target" ]]; then
        printf 'Unexpected Python tool-cache target: %s\n' "$existing_target" >&2
        exit 1
    fi
else
    ln -s "$python_prefix" "$python_cache_link"
fi

touch "$python_cache_marker"
chown -h "$RUNNER_USER:$runner_group" \
    "$python_cache_link" \
    "$python_cache_marker"

externally_managed="$python_prefix/lib/python$python_minor/EXTERNALLY-MANAGED"
if [[ -f $externally_managed ]]; then
    mv "$externally_managed" "$externally_managed.uv"
fi

printf 'Verifying the runner build environment...\n'
runuser -u "$RUNNER_USER" -- bash -c 'cc --version | head -n1'
runuser -u "$RUNNER_USER" -- \
    "$python_cache_link/bin/python" --version

printf 'Runner build-tool provisioning completed.\n'
