# Homelab Infrastructure

Reproducible configuration and provisioning for a Proxmox-based homelab.

The repository starts with the Linux GitHub Actions runner build environment.
Additional VM definitions, cloud-init configuration, and services can be added
as they are converted from validated manual procedures.

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
