# Current Status

Last verified: 2026-10-04 (America/New_York)

This file is the durable handoff for active homelab work. Verify mutable
external state before acting, but do not reconstruct the project solely from
chat history. See [`ROADMAP.md`](ROADMAP.md) for the overall project direction.

## Active objective

Roadmap phase 2 is complete. The Debian 13 Linux runner lifecycle on `pve04`
has been exercised from a clean template clone through bootstrap,
registration, representative CI, unregister, and deletion.

The runner planning objective remains phase 3: determine the required Linux
runner fleet from measured demand before creating or retaining additional
workers. Roadmap phase 4 is operational: `pve05` is the fifth member of the
`homelab` cluster and hosts the dedicated Windows 11 lab workstation.

Linux CI is now consolidated on `gha-linux-01`. The older `ubuntuserver`
GitHub runner registration and its VM on the Synology DS923+ have both been
deleted.

The earlier Ubuntu-on-`pve02` proposal is superseded. No separate runner on
`pve02` is currently required; revisit that option only in response to
measured capacity, redundancy, compatibility, or isolation needs.

## Live runner state

As of the last verification:

- `gha-linux-01` is online and idle.
- GitHub Actions runner version: `2.337.0`.
- Organization runner group: `trusted-ci`.
- Labels: `self-hosted`, `Linux`, `X64`, `debian-13`, and `ci`.
- The runner group is limited to `gtvfx-envoy/envoy`,
  `gtvfx-envoy/devtools`, `gtvfx-envoy/robinhood`,
  `gtvfx-envoy/validation`, `gtvfx-envoy/despatch`, and
  `gtvfx-envoy/envoy_utils`.
- The validated VM profile is Debian 13 with 4 vCPUs, 8 GiB fixed memory, and
  a 120 GiB SCSI system disk.
- Proxmox VM 104, `debian13-gha-runner-template`, is a stopped, unregistered
  template with cloud-init identity regeneration and no embedded runner
  credentials.
- After acceptance cleanup, `pve04` contains only production runner VM 103
  and template VM 104. The `pve04-nvme` thin pool was 1.57% allocated.
- GitHub runner ID 11, `ubuntuserver`, was removed from the organization on
  2026-10-03 after its Linux workflow repositories were granted access to
  `trusted-ci`. The organization runner inventory now contains only
  `gha-linux-01` and the Windows runner `MINI-PC`.
- The associated `ubuntuserver` VM was subsequently deleted from the Synology
  DS923+. It was the final VM running on that NAS.

## Proxmox node access

Key-only, non-interactive root SSH access was verified from the Codex host to
all five nodes on 2026-10-03:

- `pve01`: Proxmox VE 9.2.11, kernel 7.0.14-14-pve
- `pve02`: Proxmox VE 9.2.11, kernel 7.0.14-14-pve
- `pve03`: Proxmox VE 9.2.11, kernel 7.0.14-14-pve
- `pve04`: Proxmox VE 9.2.21, kernel 7.0.14-20-pve
- `pve05`: Proxmox VE 9.2.21, kernel 7.0.14-20-pve

Connection addresses and private key material are intentionally excluded from
this public repository. Protected local SSH aliases for the original four
nodes are configured on the Windows Codex host. Direct key-only access to
`pve05` is verified; adding its local alias remains housekeeping.

## `pve05` expansion

`pve05` is a Dell OptiPlex Micro 7010 with an Intel Core i5-13500T, 64 GiB of
memory, and a 1 TB NVMe device. It joined the `homelab` cluster as node ID 5
on 2026-10-03 and hosts VM 105, the Windows 11 lab workstation.

Cluster admission was explicitly authorized on 2026-10-03. The final
preflight confirmed that the existing four-node cluster was healthy and
quorate, both sides ran Proxmox VE `9.2.21` with kernel `7.0.14-20-pve`,
`pve05` was empty and standalone, its hostname resolved to its intended
management address, and all four members were reachable without packet loss.

Pre-join preparation was completed and validated on 2026-10-03:

- the timezone was corrected to `America/New_York`, with NTP synchronized;
- the unusable enterprise PVE and Ceph sources were renamed with `.disabled`
  suffixes rather than deleted;
- the official `pve-no-subscription` repository was enabled;
- 182 packages were upgraded successfully;
- the node rebooted into kernel `7.0.14-20-pve` with Proxmox VE `9.2.21`,
  exactly matching `pve04`;
- `pveproxy`, `pvedaemon`, `pvestatd`, SSH, and Chrony were active, with no
  failed systemd units and no pending package or reboot requirement;
- local and local-LVM storage were active, and the management bridge retained
  its expected address and default route; and
- the existing four-node `homelab` cluster remained healthy and quorate.

The supported SSH-mode `pvecm add` workflow then completed successfully with
`pve05`'s management address explicitly assigned to Corosync link 0.
Post-join validation from both `pve04` and `pve05` confirmed:

- cluster configuration version 5 with node IDs 1 through 5;
- five expected and present votes, quorum 3, and a quorate state;
- active Corosync, `pve-cluster`, API proxy, daemon, and status services;
- no failed systemd units;
- replicated cluster visibility of all five node directories; and
- an active, empty 793.8 GiB `local-lvm` thin pool on `pve05` after extending
  the existing storage definition to nodes `pve02`, `pve03`, and `pve05`.

The Synology `/volume1/proxmox` NFS export ACL was expanded to include
`pve05`. The shared storage then mounted automatically on `pve05` using NFS
4.1, was readable, and reported the same healthy capacity and usage as on
`pve04`. Five-node quorum and all cluster services remained healthy after the
ACL change.

Before the join, the only error-level current-boot journal entry was `blkmapd`
reporting a missing NFS block-layout pipe. The event did not affect node,
local storage, network, API, or Proxmox service health and is separate from
the explicit Synology export ACL rejection observed after the join.

VM 105, `win11-lab-workstation`, was created on `pve05` as a powered-off VM
shell separate from `win-jump`. Its validated configuration has 8 host-type
vCPUs, 24 GiB fixed memory, a 256 GiB thin-provisioned VirtIO SCSI disk, Q35,
OVMF with Microsoft Secure Boot keys, TPM 2.0, a VirtIO NIC on `vmbr0`, and
QEMU guest-agent support. The Windows 11 25H2 and VirtIO driver ISOs are
attached from shared storage. The generated QEMU command validated, and the
new volumes left `local-lvm` at 0.01% allocation.

Use individual USB device or physical-port mappings instead of
whole-controller passthrough because `pve05` has one USB controller shared
with its USB network adapter and internal Bluetooth. Dell documents six
built-in external USB ports: two front USB 3.2 ports, two rear USB 3.2 ports,
one rear USB 2.0 port, and one rear USB 2.0 Smart Power On port. Their stable
Linux port paths were mapped with a USB 3 flash drive and USB 2 mouse. Ten
speed-specific port paths were attached to VM 105, covering both the USB 3 and
USB 2 companion paths for each USB 3 connector while excluding internal
Bluetooth. The unused Realtek USB Ethernet adapter was removed after
confirming that `pve05` management and Corosync use the onboard NIC. Removing
it did not affect connectivity or five-node quorum.

VM 105 then started successfully, initialized its virtual TPM 2.0, and
accepted the boot keystroke after a controlled reset. Windows 11 Pro setup was
completed and the user signed in. The full VirtIO guest-tools package was
installed; the QEMU guest agent now reports the OS, active VirtIO network
interface, DHCP address, and Windows filesystems to Proxmox. Both installation
ISOs were ejected.

RDP is enabled with Network Level Authentication. Only the standard RDP
TCP/UDP user-mode firewall rules are enabled, the active VirtIO network is
classified as Private, and the rules are restricted to the trusted LAN
subnet. TCP port 3389 was reachable from the Codex workstation and local name
resolution identifies the guest. An interactive RDP sign-in then succeeded
using a password-protected local administrator account. Windows confirmed the
account is enabled and belongs to both the local Administrators and Users
groups.

The Windows update loop completed on 2026-10-04. An offered preview cumulative
update was intentionally deferred. A signed RDP profile was validated with
multi-monitor display, clipboard sharing, local audio, NLA, and restricted
device redirection; private endpoint, account, and certificate identifiers are
excluded from this repository.

During a controlled stopped cycle, the VM boot order was normalized to the
VirtIO system disk only. Snapshot `baseline-2026-10-04` captured the system,
EFI, and TPM disks. A separate compressed full backup then completed
successfully on shared Synology storage; the 256 GiB thin disk produced a
38.76 GB archive. The VM restarted from the corrected boot target, and the
QEMU guest agent plus expected VirtIO network interface returned successfully.

Windows OpenSSH Server was then installed for repeatable remote administration.
The service starts automatically, accepts only the designated local
administrator, and uses the Codex host's existing Ed25519 public key. Password
and keyboard-interactive SSH authentication are disabled. The inbound firewall
rule is limited to the Private profile and trusted LAN. Post-hardening tests
confirmed that key authentication succeeds, a no-key connection is rejected,
stable-name resolution works, and WinGet is available in the administrator's
user context. The QEMU guest agent remains an independent recovery channel.

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
- The `ubuntuserver` retirement transition expanded `trusted-ci` access only
  to the four repositories with existing generic self-hosted Linux jobs:
  `robinhood`, `validation`, `despatch`, and `envoy_utils`. After runner ID 11
  was removed, the
  [Robinhood routing check](https://github.com/gtvfx-envoy/robinhood/actions/runs/37145696049)
  ran on `gha-linux-01` in `trusted-ci` and passed all CI and cleanup steps.
- The retired `ubuntuserver` VM was then deleted from Synology Virtual Machine
  Manager, completing removal of the final VM workload from the DS923+.

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

1. Add a reviewed WinGet Configuration baseline for the Windows workstation,
   covering core utilities and deliberately selected runtime versions. Keep
   authentication and machine-private values out of the public repository.
2. Consider pinning remaining generic self-hosted Linux workflow selectors to
   the custom `debian-13` and `ci` labels so future generic runners cannot
   receive those jobs accidentally.
3. Use measured queueing and utilization to decide whether more than
   `gha-linux-01` is needed. Do not create a fleet merely because the template
   supports one.
4. Define a lightweight update, health-check, and replacement procedure for
   `gha-linux-01` and template VM 104.
5. If the cache post-job stall recurs, capture the live service journal and
   runner diagnostics before restarting anything.

Puppet is deferred until a larger Windows fleet or continuous drift-remediation
requirement justifies its operating overhead. Start with WinGet Configuration
and reviewed manual upgrades; do not schedule a blanket `winget upgrade --all`
until package behavior has been observed.

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
