# Homelab Infrastructure

Reproducible configuration and provisioning for a Proxmox-based homelab.

The repository starts with the Linux GitHub Actions runner build environment.
Additional VM definitions, cloud-init configuration, and services can be added
as they are converted from validated manual procedures.

## Project direction

Read [`ROADMAP.md`](ROADMAP.md) for the evolving long-term vision, operating
principles, phased infrastructure plan, and completion criteria. The roadmap
is expected to change as evidence and needs develop.

## Current status

Read [`STATUS.md`](STATUS.md) before continuing active work. It records the
last verified live state, completed evidence, known problems, and next actions.

## Security boundaries

This repository is public. Never commit:

- GitHub runner registration tokens or credentials
- private SSH keys or passwords
- rendered cloud-init user data containing secrets
- Terraform state or non-example variable files
- backup archives, recovery keys, or private network captures

Runner registration is intentionally separate from reusable VM provisioning.
Each cloned worker must receive a new hostname, machine identity, SSH host keys,
and GitHub runner identity.

## Linux runner

The validated Debian 13 runner configuration is documented under
[`runners/linux`](runners/linux/README.md). Its provisioning script installs
the native compiler toolchain and prepares Python 3.11.9 for compatibility with
`actions/setup-python` on this otherwise unsupported distribution.

## Proxmox nodes

Common host configuration is documented under
[`nodes/common`](nodes/common/README.md). The initial policy enables key-only
SSH administration while retaining key-based root access for Proxmox
maintenance.

## Windows lab workstation

The Windows 11 sandbox and trusted Windows CI runner on `pve05`, including its
VM profile, service boundary, and physical USB port map, is documented under
[`vms/windows-workstation`](vms/windows-workstation/README.md).
