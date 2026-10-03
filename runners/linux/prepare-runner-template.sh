#!/usr/bin/env bash

set -euo pipefail

ADMIN_USER="${ADMIN_USER:-labadmin}"
RUNNER_USER="${RUNNER_USER:-runner}"
STALE_USER="${STALE_USER:-}"

if [[ $EUID -ne 0 ]]; then
    printf 'Run this script as root.\n' >&2
    exit 1
fi

if [[ ${CONFIRM_TEMPLATE_PREPARATION:-} != yes ]]; then
    printf 'Set CONFIRM_TEMPLATE_PREPARATION=yes to prepare this host as a template.\n' >&2
    exit 1
fi

if ! getent passwd "$RUNNER_USER" >/dev/null || \
    ! getent passwd "$ADMIN_USER" >/dev/null; then
    printf 'Required administrative or runner account is missing.\n' >&2
    exit 1
fi

runner_home="$(getent passwd "$RUNNER_USER" | cut -d: -f6)"
admin_home="$(getent passwd "$ADMIN_USER" | cut -d: -f6)"

if [[ $runner_home != /home/* || $admin_home != /home/* ]]; then
    printf 'Refusing unexpected account home path.\n' >&2
    exit 1
fi

for credential_file in \
    "$runner_home/actions-runner/.runner" \
    "$runner_home/actions-runner/.credentials" \
    "$runner_home/actions-runner/.credentials_rsaparams"; do
    if [[ -e $credential_file ]]; then
        printf 'Refusing to template a registered runner: %s\n' "$credential_file" >&2
        exit 1
    fi
done

if compgen -G '/etc/systemd/system/actions.runner.*.service' >/dev/null; then
    printf 'Refusing to template a host with a runner service installed.\n' >&2
    exit 1
fi

if [[ -n $STALE_USER ]]; then
    if [[ $STALE_USER == root || $STALE_USER == "$ADMIN_USER" || \
        $STALE_USER == "$RUNNER_USER" ]]; then
        printf 'Refusing to remove protected account: %s\n' "$STALE_USER" >&2
        exit 1
    fi

    if getent passwd "$STALE_USER" >/dev/null; then
        printf 'Removing explicitly selected stale account: %s\n' "$STALE_USER"
        userdel --remove "$STALE_USER"
    fi
fi

printf 'Removing clone-specific access and transient state...\n'
rm -rf "$admin_home/.ssh"
rm -f \
    "$admin_home/.bash_history" \
    /root/.bash_history \
    /root/.ssh/known_hosts \
    /tmp/bootstrap-runner-host.sh \
    /tmp/provision-build-tools.sh

apt-get clean
cloud-init clean --logs --machine-id --seed --configs all
rm -f \
    /etc/ssh/ssh_host_* \
    /etc/sudoers.d/90-cloud-init-users \
    /var/lib/systemd/random-seed

sync
printf 'Template preparation completed. Powering off now.\n'
systemctl poweroff
