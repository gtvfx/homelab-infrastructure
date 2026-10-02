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

## Registration boundary

Download and registration of the GitHub Actions runner remain separate because
registration tokens are short-lived credentials and must never be baked into a
template. After cloning a reusable VM, configure and install its runner service
using a newly generated organization registration token.
