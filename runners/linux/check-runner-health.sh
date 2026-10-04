#!/usr/bin/env bash

set -u
set -o pipefail

RUNNER_USER="${RUNNER_USER:-runner}"
RUNNER_ROOT="${RUNNER_ROOT:-}"
RUNNER_SERVICE="${RUNNER_SERVICE:-}"
WORKSPACE_WARNING_PERCENT="${WORKSPACE_WARNING_PERCENT:-80}"

failures=0
warnings=0

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

pass() {
    printf 'PASS  %s\n' "$1"
}

warn() {
    printf 'WARN  %s\n' "$1"
    warnings=$((warnings + 1))
}

fail() {
    printf 'FAIL  %s\n' "$1" >&2
    failures=$((failures + 1))
}

checkService() {
    local service_name="$1"

    if systemctl is-active --quiet "$service_name"; then
        pass "$service_name is active"
    else
        fail "$service_name is not active"
    fi

    if systemctl is-enabled --quiet "$service_name"; then
        pass "$service_name is enabled"
    else
        fail "$service_name is not enabled"
    fi
}

checkDisk() {
    local path="$1"
    local usage_percent

    if [[ ! -e $path ]]; then
        fail "disk-check path does not exist: $path"
        return
    fi

    usage_percent="$(df -P "$path" | awk 'NR == 2 {gsub(/%/, "", $5); print $5}')"
    if [[ ! $usage_percent =~ ^[0-9]+$ ]]; then
        fail "could not determine disk usage for $path"
    elif ((usage_percent >= WORKSPACE_WARNING_PERCENT)); then
        warn "$path filesystem is ${usage_percent}% full"
    else
        pass "$path filesystem is ${usage_percent}% full"
    fi
}

printf 'Linux runner health check: %s (%s)\n' "$(hostname -s)" "$(date --iso-8601=seconds)"

if [[ -z $RUNNER_SERVICE ]]; then
    mapfile -t runner_services < <(
        systemctl list-unit-files --type=service --no-legend \
            'actions.runner.*.service' | awk '{print $1}'
    )
    if ((${#runner_services[@]} == 1)); then
        RUNNER_SERVICE="${runner_services[0]}"
    elif ((${#runner_services[@]} == 0)); then
        fail "no GitHub Actions runner systemd service was found"
    else
        fail "multiple runner services found; set RUNNER_SERVICE explicitly"
    fi
fi

if [[ -n $RUNNER_SERVICE ]]; then
    checkService "$RUNNER_SERVICE"
fi

if [[ -f $RUNNER_ROOT/.runner ]]; then
    pass "runner registration metadata is present"
else
    fail "runner registration metadata is absent from $RUNNER_ROOT"
fi

runner_listener="$RUNNER_ROOT/bin/Runner.Listener"
if [[ -x $runner_listener ]]; then
    runner_version="$(
        runuser -u "$RUNNER_USER" -- "$runner_listener" --version 2>/dev/null || true
    )"
    if [[ -n $runner_version ]]; then
        pass "GitHub Actions runner version: $runner_version"
    else
        fail "GitHub Actions runner version could not be read"
    fi
else
    fail "GitHub Actions runner listener is missing or not executable"
fi

if systemctl is-active --quiet qemu-guest-agent.service; then
    pass "qemu-guest-agent.service is active"
else
    fail "qemu-guest-agent.service is not active"
fi

checkDisk /
if [[ -d $RUNNER_ROOT/_work ]]; then
    checkDisk "$RUNNER_ROOT/_work"
else
    warn "runner workspace does not exist yet: $RUNNER_ROOT/_work"
fi

if [[ -f /var/run/reboot-required ]]; then
    warn "the operating system reports that a reboot is required"
else
    pass "no reboot-required marker is present"
fi

printf '\nSystem summary\n'
printf '  Kernel: %s\n' "$(uname -r)"
printf '  Uptime: %s\n' "$(uptime -p)"
free -h | awk 'NR == 2 {printf "  Memory: %s used / %s total\n", $3, $2}'

printf '\nToolchain summary\n'
printf '  Git: %s\n' "$(git --version 2>/dev/null || printf 'unavailable')"
printf '  C compiler: %s\n' "$(cc --version 2>/dev/null | head -n1 || printf 'unavailable')"
uv_binary="$runner_home/.local/bin/uv"
if [[ -x $uv_binary ]]; then
    printf '  uv: %s\n' "$(runuser -u "$RUNNER_USER" -- "$uv_binary" --version 2>/dev/null)"
else
    warn "uv is not installed at $uv_binary"
fi

printf '\nResult: %d failure(s), %d warning(s)\n' "$failures" "$warnings"
if ((failures > 0)); then
    exit 1
fi
