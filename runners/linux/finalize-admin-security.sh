#!/usr/bin/env bash

set -euo pipefail

ADMIN_USER="${ADMIN_USER:-labadmin}"
CLOUD_INIT_SUDOERS="${CLOUD_INIT_SUDOERS:-/etc/sudoers.d/90-cloud-init-users}"
PROVISION_SUDOERS="${PROVISION_SUDOERS:-/etc/sudoers.d/labadmin-runner-provision}"

if [[ $EUID -ne 0 ]]; then
    printf 'Run this script as root.\n' >&2
    exit 1
fi

if [[ ${CONFIRM_ADMIN_HARDENING:-} != yes ]]; then
    printf 'Set CONFIRM_ADMIN_HARDENING=yes to finalize the sudo policy.\n' >&2
    exit 1
fi

if ! getent passwd "$ADMIN_USER" >/dev/null; then
    printf 'Administrative account does not exist: %s\n' "$ADMIN_USER" >&2
    exit 1
fi

password_status="$(passwd --status "$ADMIN_USER" | awk '{print $2}')"
if [[ $password_status != P ]]; then
    printf 'Set a password for %s before removing temporary passwordless sudo.\n' \
        "$ADMIN_USER" >&2
    exit 1
fi

if ! id -nG "$ADMIN_USER" | tr ' ' '\n' | grep -Fxq sudo; then
    printf 'Administrative account is not a member of the sudo group.\n' >&2
    exit 1
fi

effective_sshd_configuration="$(sshd -T)"
if ! grep -Fxq 'passwordauthentication no' <<<"$effective_sshd_configuration"; then
    printf 'Refusing to finalize while SSH password authentication is enabled.\n' >&2
    exit 1
fi

if [[ ! -f $PROVISION_SUDOERS ]]; then
    printf 'Required narrow provisioning rule is missing: %s\n' \
        "$PROVISION_SUDOERS" >&2
    exit 1
fi

visudo -cf "$PROVISION_SUDOERS"

if [[ ! -e $CLOUD_INIT_SUDOERS ]]; then
    visudo -c
    printf 'Administrative sudo policy is already finalized.\n'
    exit 0
fi

backup_file="$(mktemp /tmp/cloud-init-sudoers.XXXXXX)"
trap 'rm -f "$backup_file"' EXIT
cp --preserve=mode,ownership,timestamps "$CLOUD_INIT_SUDOERS" "$backup_file"
rm -f "$CLOUD_INIT_SUDOERS"

if ! visudo -c; then
    install -o root -g root -m 0440 "$backup_file" "$CLOUD_INIT_SUDOERS"
    printf 'Sudo validation failed; temporary cloud-init policy was restored.\n' >&2
    exit 1
fi

printf 'Removed temporary cloud-init passwordless sudo for %s.\n' "$ADMIN_USER"
printf 'General sudo now requires the account password.\n'
