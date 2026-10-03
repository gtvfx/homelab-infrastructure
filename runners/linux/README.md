# Linux GitHub Actions runner

This directory captures the reusable build environment for the self-hosted
Linux runner. It does not register a runner with GitHub.

## Validated configuration

- Debian 13 x86-64 guest
- dedicated `labadmin` administrative account
- unprivileged `runner` service account
- GitHub Actions runner installed at `/home/runner/actions-runner`
- runner service managed by systemd as `runner`
- labels: `self-hosted`, `Linux`, `X64`, `debian-13`, `ci`
- organization runner group: `trusted-ci`

The build environment has been validated with Python linting, native Rust
formatting/Clippy/tests, PyO3 linking, wheel building, and Python contract tests.

The validated virtual hardware is documented in the
[`proxmox`](proxmox/README.md) profile. Host-specific identifiers and GitHub
registration remain outside that reusable definition.

## Provision build tools

Run from an administrative account with root privileges:

```bash
sudo bash runners/linux/provision-build-tools.sh
```

The script:

1. Installs the Debian native compiler toolchain.
2. Installs pinned `uv` for the `runner` account.
3. Installs pinned Python 3.11.9 with `uv`.
4. Exposes that interpreter through the GitHub runner tool cache.
5. Makes the dedicated CI interpreter pip-installable.
6. Verifies compiler and Python access as `runner`.

Versions and paths can be overridden with environment variables documented at
the top of the script.

## Bootstrap a fresh host

Run [`bootstrap-runner-host.sh`](bootstrap-runner-host.sh) as root on a fresh
Debian cloud-image clone. It:

1. Installs Git and other bootstrap prerequisites.
2. Creates the locked, unprivileged `runner` service account.
3. Maintains a root-owned checkout at `/opt/homelab-infrastructure`.
4. Installs and validates the narrow provisioning sudo rule.
5. Runs the build-tool provisioner.

The cloud-image administrative account may temporarily use passwordless sudo
for unattended bootstrap. Establish the intended long-term administrative
authentication and sudo policy before treating a clone as production-ready.
The bootstrap does not download or register a GitHub Actions runner.

## Prepare a golden image

After validating a newly bootstrapped, unregistered VM, use
[`prepare-runner-template.sh`](prepare-runner-template.sh) to remove
clone-specific identity and power it off for conversion to a Proxmox template.
The script refuses to run if it detects GitHub runner credentials or a runner
systemd service.

Template preparation is intentionally guarded:

```bash
sudo env CONFIRM_TEMPLATE_PREPARATION=yes \
  bash /opt/homelab-infrastructure/runners/linux/prepare-runner-template.sh
```

Set `STALE_USER` only when a source image contains an account that must not be
carried into the template. The script removes that account and its home
directory, so inspect the guest first and specify the account explicitly.

Cloud-init injects the administrative SSH key and regenerates the machine ID,
SSH host keys, network configuration, and temporary administrative sudo policy
when a clone first boots. Complete the intended long-term sudo policy before
registering the clone with GitHub.

## Install and register the runner

Runner binary installation and GitHub registration are separate operations.
[`install-github-runner.sh`](install-github-runner.sh) downloads the pinned
Linux x64 release, verifies its GitHub-published SHA-256 digest, installs its
runtime dependencies, and leaves the host unregistered:

```bash
sudo bash /opt/homelab-infrastructure/runners/linux/install-github-runner.sh
```

Generate a short-lived organization registration token immediately before
registration. Pipe it over SSH standard input so it is not saved in this
repository, a template, shell profile, or command transcript:

```bash
gh api --method POST \
  orgs/gtvfx-envoy/actions/runners/registration-token \
  --jq .token | \
ssh <admin-host> \
  'sudo bash /opt/homelab-infrastructure/runners/linux/register-github-runner.sh'
```

Registration defaults to organization `gtvfx-envoy`, runner group
`trusted-ci`, and custom labels `debian-13,ci`. The runner name defaults to the
short hostname. Override the documented environment variables only when the
new worker intentionally differs from this profile.

Set `RUNNER_DISABLE_DEFAULT_LABELS=1` for an isolated validation registration
that should receive only its explicitly configured custom labels.

Removal also requires a newly generated short-lived token, sent through the
same channel:

```bash
gh api --method POST \
  orgs/gtvfx-envoy/actions/runners/remove-token \
  --jq .token | \
ssh <admin-host> \
  'sudo bash /opt/homelab-infrastructure/runners/linux/unregister-github-runner.sh'
```

The registration scripts never print or persist the supplied token. GitHub's
runner configuration stores its own credentials under the runner account after
successful registration; those files must never be copied into a template.

## Optional remote maintenance

The example policy in
[`sudoers.d/labadmin-runner-provision`](sudoers.d/labadmin-runner-provision)
allows `labadmin` to run only the root-owned provisioning script without a
password. It does not grant unrestricted passwordless sudo access.

Install and validate it as root:

```bash
install -o root -g root -m 0440 \
  runners/linux/sudoers.d/labadmin-runner-provision \
  /etc/sudoers.d/labadmin-runner-provision
visudo -cf /etc/sudoers.d/labadmin-runner-provision
```

Keep `/opt/homelab-infrastructure` and the authorized script root-owned. If an
unprivileged account can edit the script, this narrow rule becomes equivalent
to unrestricted root access.

## Registration boundary

Download and registration of the GitHub Actions runner remain separate because
registration tokens are short-lived credentials and must never be baked into a
template. After cloning a reusable VM, configure and install its runner service
using a newly generated organization registration token.
