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

**State:** Operational, with ongoing documentation and hardening.

Maintain the four-node Proxmox environment, shared Synology-backed storage,
networking, key-only administrative access, hardware inventory, recovery
procedures, and safe storage-management practices.

### 2. Reusable Linux GitHub Actions runner template

**State:** Active priority.

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

**State:** Planned after phase 2.

Create multiple independently registered Linux workers from the validated
template. Define capacity, labels, runner groups, repository access,
concurrency, update policy, health checks, replacement procedure, and workload
placement using measured demand.

### 4. Reusable Windows GitHub Actions runner template

**State:** Planned.

Build a reproducible Windows runner image for Windows-native builds and tests.
Keep runner registration, machine identity, credentials, and repository state
out of the template.

### 5. Windows runner fleet

**State:** Planned after phase 4.

Deploy and operate independently identifiable Windows workers with documented
security boundaries, update policy, workload isolation, and replacement
procedures.

### 6. macOS GitHub Actions runner

**State:** Planned.

Use the existing Mac mini as a self-hosted macOS runner. Document registration,
labels, access scope, update policy, health monitoring, and recovery behavior.

### 7. OpenCue

**State:** Planned.

Evaluate and deploy OpenCue as a render-farm and workload orchestration
environment, with documented storage, worker, network, and authentication
requirements.

### 8. Jellyfin and media services

**State:** Planned; exploratory work exists.

Develop reproducible media-service hosting, encoding automation, storage
layout, naming conventions, GPU use, backups, and operational documentation.

### 9. Home Assistant, MQTT, and related services

**State:** Planned.

Provide isolated, maintainable home-automation services with clear network,
backup, upgrade, and device-integration boundaries.

### 10. Kubernetes lab

**State:** Planned.

Build a learning and testing environment for cluster lifecycle, networking,
storage, ingress, secrets, deployments, and observability without making it a
dependency of unrelated homelab services.

### 11. Jenkins

**State:** Planned.

Evaluate Jenkins for workloads that benefit from it, avoiding duplication with
GitHub Actions unless there is a clear operational or educational purpose.

### 12. Monitoring and observability

**State:** Planned.

Establish node, VM, service, storage, network, and CI-runner monitoring with
useful alerting, dashboards, log retention, and documented response procedures.

### 13. Internal package, artifact, cache, and API infrastructure

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
