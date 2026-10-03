# Current Status

Last verified: 2026-10-03 (America/New_York)

This file is the durable handoff for active homelab work. Verify mutable
external state before acting, but do not reconstruct the project solely from
chat history. See [`ROADMAP.md`](ROADMAP.md) for the overall project direction.

## Active objective

Complete roadmap phase 2: turn the validated `pve04` Linux GitHub Actions
runner into a reproducible, secure runner lifecycle that can provision fresh
workers and, eventually, a clean Proxmox template.

The earlier Ubuntu-on-`pve02` proposal is superseded. No separate runner on
`pve02` is currently required; revisit that option only in response to
measured capacity, redundancy, compatibility, or isolation needs.

## Live runner state

As of the last verification:

- `gha-linux-01` is online and idle.
- GitHub Actions runner version: `2.337.0`.
- Organization runner group: `trusted-ci`.
- Labels: `self-hosted`, `Linux`, `X64`, `debian-13`, and `ci`.
- The runner group is limited to `gtvfx-envoy/envoy` and
  `gtvfx-envoy/devtools`.
- The validated VM profile is Debian 13 with 4 vCPUs, 8 GiB fixed memory, and
  a 120 GiB SCSI system disk.

## Proxmox node access

Key-only, non-interactive root SSH access was verified from the Codex host to
all four nodes on 2026-10-03:

- `pve01`: Proxmox VE 9.2.11, kernel 7.0.14-14-pve
- `pve02`: Proxmox VE 9.2.11, kernel 7.0.14-14-pve
- `pve03`: Proxmox VE 9.2.11, kernel 7.0.14-14-pve
- `pve04`: Proxmox VE 9.2.21, kernel 7.0.14-20-pve

Connection addresses and private key material are intentionally excluded from
this public repository. Protected local SSH aliases for `pve01` through
`pve04` are configured on the Windows Codex host and were verified with
non-interactive connections.

## Completed validation

The following evidence confirms the runner can execute the intended workloads:

- [PR #40](https://github.com/gtvfx-envoy/envoy/pull/40) added the manual
  `pve04` Python validation workflow.
- [Validation run #5](https://github.com/gtvfx-envoy/envoy/actions/runs/37023970375)
  passed Python 3.11.9 setup, Ruff lint, and Ruff formatting on
  `gha-linux-01`.
- [PR #41](https://github.com/gtvfx-envoy/envoy/pull/41) expanded validation
  to Rust.
- [Validation run #6](https://github.com/gtvfx-envoy/envoy/actions/runs/37072574819)
  passed Python lint plus Rust formatting, Clippy, and native tests on
  `gha-linux-01`.
- After PR #41 merged, the normal
  [Lint run](https://github.com/gtvfx-envoy/envoy/actions/runs/37073188390)
  successfully completed the PyO3 job on `gha-linux-01`, including Rust
  checks, wheel construction, wheel installation, Python contract tests, and
  consumer smoke tests.
- The associated
  [Deploy Docs run](https://github.com/gtvfx-envoy/envoy/actions/runs/37073188395)
  successfully built internal Rust documentation on `gha-linux-01`.

## Known unresolved issue

The normal Lint run above concluded as failed even though all commands in its
native Rust job passed. The job then remained in
`Post Cache cargo registry/build artifacts` from 18:37:18 until GitHub ended
the job at 18:46:34. `Post Checkout` never started.

This points to a post-job cache finalization or runner communication problem,
not a compiler or test failure. The historical job log download currently
returns `BlobNotFound`, so the failure should be reproduced before changing
the runner or workflow.

## Provisioning work captured here

The repository now contains:

- the validated build-tool provisioner;
- fresh-host bootstrap;
- guarded template preparation;
- separate runner installation, registration, and removal scripts;
- secure registration-token handoff over standard input;
- scoped administrative sudo policy;
- administrative hardening finalization;
- a reusable Proxmox VM hardware profile; and
- common key-only SSH policy for Proxmox nodes.

These scripts were added after much of the original runner validation. Their
presence in the repository does not prove that the complete fresh-clone
lifecycle has been exercised end to end.

## Next actions

1. Re-run the normal Envoy Lint workflow or an equivalent cache-enabled job on
   `gha-linux-01`.
2. If the cache post-job step stalls again, capture the live runner service
   journal and runner diagnostic logs before restarting anything.
3. Verify whether `finalize-admin-security.sh` has been applied to the
   current guest: key-only SSH should work, `labadmin` should retain
   password-backed sudo, and cloud-init's temporary unrestricted
   `NOPASSWD:ALL` file should be absent.
4. Exercise the documented lifecycle on a fresh Proxmox clone:
   bootstrap, install, register with a new short-lived token, run validation,
   unregister, and prepare a clean template.
5. Only after that end-to-end test passes should the VM be treated as a
   reproducible golden-image workflow.

## Continuity protocol

At the start of future homelab sessions:

1. Read this file, [`ROADMAP.md`](ROADMAP.md), and the relevant component
   README.
2. Inspect recent commits and current GitHub Actions state.
3. Verify mutable live facts such as runner status before relying on this
   snapshot.

After each material milestone and before ending a session, update this file
with completed evidence, unresolved problems, and the single most useful next
action.
