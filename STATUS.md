# Current Status

Last verified: 2026-10-03 (America/New_York)

This file is the durable handoff for active homelab work. Verify mutable
external state before acting, but do not reconstruct the project solely from
chat history. See [`ROADMAP.md`](ROADMAP.md) for the overall project direction.

## Active objective

Roadmap phase 2 is complete. The Debian 13 Linux runner lifecycle on `pve04`
has been exercised from a clean template clone through bootstrap,
registration, representative CI, unregister, and deletion.

The immediate planning objective is phase 3: determine the required Linux
runner fleet from measured demand before creating or retaining additional
workers.

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
- Proxmox VM 104, `debian13-gha-runner-template`, is a stopped, unregistered
  template with cloud-init identity regeneration and no embedded runner
  credentials.
- After acceptance cleanup, `pve04` contains only production runner VM 103
  and template VM 104. The `pve04-nvme` thin pool was 1.57% allocated.
- An older organization runner named `ubuntuserver` was also observed online.
  Its host, purpose, recent utilization, and continued need have not yet been
  reconciled with the decision that a separate Ubuntu runner is unnecessary.

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
- Attempt 2 of the normal
  [Lint run](https://github.com/gtvfx-envoy/envoy/actions/runs/37073188390)
  completed successfully on 2026-10-03. The native Rust job, cache post-job,
  checkout cleanup, and complete workflow all passed.
- A full temporary clone of template VM 104 was created as VM 105. Proxmox
  generated a new MAC address, SMBIOS UUID, VM generation ID, disks, and
  hostname; cloud-init completed and generated a fresh guest machine ID and
  working key-only SSH access.
- The clone contained no inherited runner service or registration credentials.
  The documented bootstrap fast-forwarded its infrastructure checkout to
  `e947645`, verified GCC and Python 3.11.9, and the runner installer verified
  the SHA-256 digest for GitHub Actions runner `2.337.0`.
- The clone registered as `gha-linux-template-smoke` with only the isolated
  `template-smoke` label. The
  [template acceptance run](https://github.com/gtvfx-envoy/envoy/actions/runs/37143740904)
  passed Python lint/formatting and Rust formatting, Clippy, tests, cache
  finalization, and checkout cleanup.
- The temporary runner was cleanly unregistered and disappeared from the
  organization runner list. VM 105 and its dedicated volumes were then
  deleted, and the temporary validation branch was removed.

## Resolved cache observation

The first attempt of the normal Lint run above concluded as failed even though
all commands in its native Rust job passed. The job then remained in
`Post Cache cargo registry/build artifacts` from 18:37:18 until GitHub ended
the job at 18:46:34. `Post Checkout` never started.

The failed jobs were rerun without changing the runner or workflow. Attempt 2
completed the same cache post-job successfully, and the independent template
acceptance run also completed cache finalization. The original event is
therefore treated as transient unless it recurs.

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

The complete fresh-clone lifecycle was exercised successfully on 2026-10-03.
Production administrative hardening was also verified: SSH is key-only,
cloud-init's unrestricted passwordless sudo policy is absent, and only the
narrow root-owned provisioning command retains passwordless sudo.

## Next actions

1. Begin phase 3 with a read-only inventory of all organization Linux runners,
   especially `ubuntuserver`: identify its host, repository access, workload
   history, and any dependency on it.
2. Use measured queueing and utilization to decide whether more than
   `gha-linux-01` is currently needed. Do not create a fleet merely because
   the template now supports one.
3. If `ubuntuserver` is confirmed redundant, plan its explicit unregister and
   shutdown as a separate approved change.
4. Define a lightweight update, health-check, and replacement procedure for
   `gha-linux-01` and template VM 104.
5. If the cache post-job stall recurs, capture the live service journal and
   runner diagnostics before restarting anything.

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
