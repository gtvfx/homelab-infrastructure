# Homelab Roadmap

## Vision

Build a Proxmox-based homelab that serves two purposes:

- useful, reproducible development and CI infrastructure; and
- a practical environment for learning Linux, Proxmox, networking, storage,
  automation, orchestration, and operations.

Codex is the primary working environment for the project. Repository
documentation preserves confirmed state and operating decisions across chats,
while live system evidence remains authoritative.

## Living roadmap

This roadmap is a living planning document, not a fixed commitment. Phases,
ordering, technologies, and completion criteria should evolve as the homelab
produces new evidence and as needs change. Add, remove, merge, split, defer, or
reorder work when there is a clear reason, and record the decision so obsolete
assumptions do not quietly remain active requirements.

## Operating principles

- Prefer reproducible infrastructure over manually maintained machines.
- Make runner and service VMs disposable, independently identifiable, and
  safe to destroy and recreate.
- Use cloud-init or equivalent automation for per-instance identity and initial
  configuration.
- Keep credentials, registration tokens, private keys, runner identity,
  repository checkouts, and disposable build artifacts out of templates.
- Separate reusable base images, reusable toolchains, per-instance
  configuration, and per-repository configuration.
- Inspect live state before making changes.
- Prefer read-only investigation before modification.
- Administer interactively one safe, verifiable step at a time.
- Put warnings before commands that carry risk.
- Never wipe, format, repartition, or repurpose storage until the device model,
  serial number, purpose, health, and current contents have been verified.
- Treat documentation as a maintained record, never as authority over
  contradictory live evidence.

## Roadmap

### 1. Proxmox cluster and storage/network foundation

**State:** Operational as a five-node cluster, with ongoing hardening.

Maintain the Proxmox environment, shared Synology-backed storage, networking,
key-only administrative access, hardware inventory, recovery procedures, and
safe storage-management practices. `pve05` joined the original four-node
cluster on 2026-10-03 and was validated as the fifth voting member.

### 2. Reusable Linux GitHub Actions runner template

**State:** Completed and validated on 2026-10-03.

The original project brief proposed Ubuntu LTS on `pve02`. That proposal is
now superseded by the validated Debian 13 implementation on `pve04`,
currently represented by `gha-linux-01`. A separate Ubuntu runner on
`pve02` is not a current requirement. Reconsider it only if measured
capacity, redundancy, compatibility, or workload-isolation needs justify
another Linux runner design.

Completion requires:

- a documented and reproducible Proxmox VM profile;
- deterministic base-host and build-tool provisioning;
- unique machine, SSH, hostname, and GitHub runner identity after cloning;
- runner installation and registration only after cloning;
- secure short-lived token handling;
- validated administrative hardening;
- successful Python, Rust, PyO3, wheel, contract-test, and documentation jobs;
- successful unregister and cleanup behavior;
- an end-to-end fresh-clone test; and
- guarded preparation of a clean, unregistered template.

### 3. Linux GitHub Actions runner fleet

**State:** Next planning phase; scale only in response to measured need.

Create multiple independently registered Linux workers from the validated
template. Define capacity, labels, runner groups, repository access,
concurrency, update policy, health checks, replacement procedure, and workload
placement using measured demand.

The initial phase-3 decision consolidated current Linux CI on `gha-linux-01`.
The older `ubuntuserver` registration and its VM on the Synology DS923+ were
deleted. Additional workers are not required unless workload measurements
show that one active runner is insufficient.

### 4. Windows 11 lab workstation

**State:** Operational on `pve05`; clean baseline captured on 2026-10-04.

Create a dedicated Windows 11 Pro sandbox and interactive workstation that is
separate from the isolated `win-jump` work VM. The initial profile is 8 vCPUs,
24 GiB fixed memory, a 256 GiB thin-provisioned system disk, Q35, OVMF with
Microsoft keys, virtual TPM 2.0, VirtIO storage and networking, and the QEMU
guest agent.

Use RDP from trusted LAN or VPN paths as the primary interface. Start without
GPU passthrough. Map required external USB ports or devices individually; do
not pass through `pve05`'s only USB controller because it also hosts the USB
network adapter and internal Bluetooth and shares an IOMMU group. Establish a
clean baseline backup or snapshot before using the VM as a sandbox.

The initial Windows baseline is complete. Normal Windows updates, VirtIO
integration, local-account RDP access, the signed multi-monitor RDP profile,
disk-only boot order, a local Proxmox snapshot, and an independent backup on
shared storage were validated on 2026-10-04.

Use WinGet Configuration with PowerShell DSC as the first configuration-as-code
layer for workstation utilities and deliberate runtime versions. Begin with
reviewed, manually applied upgrades rather than an unattended blanket upgrade.
Defer Puppet until multiple Windows systems or continuous drift correction make
the additional server, agent, certificate, catalog, and module lifecycle
worthwhile.

WINLAB now also supplies trusted Windows CI capacity as an intentional
shared-role compromise. Its runner uses a non-interactive service identity and
purpose-specific labels. Retain the clean pre-runner snapshot and backup as
the recovery boundary, and move CI to a dedicated image if workload trust,
capacity, or isolation requirements outgrow this arrangement.

### 5. Reusable Windows GitHub Actions runner template

**State:** Planned.

Build a reproducible Windows runner image for Windows-native builds and tests.
Keep runner registration, machine identity, credentials, and repository state
out of the template.

### 6. Windows runner fleet

**State:** Initial capacity operational on WINLAB; dedicated fleet deferred.

Deploy and operate independently identifiable Windows workers with documented
security boundaries, update policy, workload isolation, and replacement
procedures.

The first worker is the shared-role WINLAB VM rather than a clone of a reusable
runner template. This does not complete phase 5. Use measured demand and risk
to decide whether to build a dedicated Windows runner image and additional
workers.

### 7. macOS GitHub Actions runner

**State:** Planned.

Use the existing Mac mini as a self-hosted macOS runner. Document registration,
labels, access scope, update policy, health monitoring, and recovery behavior.

### 8. OpenCue

**State:** Planned.

Evaluate and deploy OpenCue as a render-farm and workload orchestration
environment, with documented storage, worker, network, and authentication
requirements.

### 9. Jellyfin and media services

**State:** Planned; exploratory work exists.

Develop reproducible media-service hosting, encoding automation, storage
layout, naming conventions, GPU use, backups, and operational documentation.

### 10. Home Assistant, MQTT, and related services

**State:** Planned.

Provide isolated, maintainable home-automation services with clear network,
backup, upgrade, and device-integration boundaries.

### 11. Kubernetes lab

**State:** Planned.

Build a learning and testing environment for cluster lifecycle, networking,
storage, ingress, secrets, deployments, and observability without making it a
dependency of unrelated homelab services.

### 12. Jenkins

**State:** Planned.

Evaluate Jenkins for workloads that benefit from it, avoiding duplication with
GitHub Actions unless there is a clear operational or educational purpose.

### 13. Monitoring and observability

**State:** Planned.

Establish node, VM, service, storage, network, and CI-runner monitoring with
useful alerting, dashboards, log retention, and documented response procedures.

### 14. Internal package, artifact, cache, and API infrastructure

**State:** Planned.

Provide trusted internal services for packages, build artifacts, dependency
caches, container images, and APIs. Define retention, authentication, backup,
integrity, and recovery policies before treating them as production
dependencies.

## Deferred storage experiment

An unfinished experiment on `pve02` evaluated three older 2 TB Western Digital
disks. One disk showed serious SMART degradation, while extended tests were
started on the two potentially healthy disks.

Before any ZFS, formatting, partitioning, or repurposing work:

1. Re-identify every disk by model and serial number.
2. Inspect current contents and mount or pool membership.
3. Retrieve current SMART health and test results.
4. Reconcile the evidence with existing documentation.
5. Obtain explicit approval for the specific storage change.

Linux device names such as `/dev/sdb`, `/dev/sdc`, and `/dev/sdd` are not
stable identities and must not be used as the sole basis for action.

## Roadmap maintenance

- `ROADMAP.md` defines direction, sequencing, principles, and phase-level
  completion criteria.
- `STATUS.md` records current live state, evidence, unresolved issues, and
  immediate next actions.
- Component README files document implementation and operating procedures.
- `AGENTS.md` defines the rules agents must follow while working here.

Update the roadmap whenever priorities, needs, sequencing, or intended
outcomes change. Historical proposals may remain as clearly labeled context,
but they must not be mistaken for active requirements. Update status as live
work progresses. Do not mark a phase complete without concrete verification
evidence.
