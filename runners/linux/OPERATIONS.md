# Linux runner operations

This runbook covers routine health checks, reviewed updates, incident capture,
and replacement of the production Debian runner. Commands use symbolic host
names and IDs so the public repository does not disclose private addresses or
credentials.

## Operating model

- Treat `gha-linux-01` as disposable compute, not as a stateful server.
- Keep VM 104 as an unregistered template. It must never contain GitHub runner
  credentials, a copied machine identity, or a runner systemd service.
- Route production Linux jobs with all five labels: `self-hosted`, `Linux`,
  `X64`, `debian-13`, and `ci`.
- Change one layer at a time: guest packages, build tools, runner binary, or VM
  template. Validate before proceeding to the next layer.
- Never restart or replace a runner until GitHub shows it is idle.

## Routine health check

From the runner checkout, run the read-only guest check:

```bash
cd /opt/homelab-infrastructure
sudo bash runners/linux/check-runner-health.sh
```

It verifies the runner and QEMU guest-agent services, local registration
metadata, runner version, disk pressure, reboot state, and core toolchain. A
failure produces a nonzero exit status. Warnings identify conditions that need
review but do not make the host unavailable.

The guest cannot prove that GitHub considers it online or that its labels and
group are correct. Verify those mutable control-plane facts from an
authenticated administrative workstation:

```bash
gh api orgs/gtvfx-envoy/actions/runners \
  --jq '.runners[] | select(.name == "gha-linux-01") | {
    id, name, status, busy, labels: [.labels[].name]
  }'
```

Expected state when no workflow is executing:

- `status` is `online`;
- `busy` is `false`;
- labels include `self-hosted`, `Linux`, `X64`, `debian-13`, and `ci`;
- the runner is assigned to the `trusted-ci` group with only the documented
  repositories enabled.

Run the guest and GitHub checks monthly, after an update, and whenever jobs
remain queued unexpectedly. Check Proxmox separately to confirm the VM is
running on the intended node, guest-agent communication succeeds, and storage
has comfortable free capacity.

## Reviewed update procedure

Do not schedule unattended blanket upgrades on the production runner. Review
available changes and apply them during a small maintenance window:

1. Confirm GitHub reports `busy: false` and no trusted repository has a queued
   job for the runner.
2. Record the current health output and the runner version.
3. Resolve the generated service name and stop it to prevent a job from
   starting during maintenance:

   ```bash
   runner_service="$(
     systemctl list-unit-files --type=service --no-legend \
       'actions.runner.*.service' | awk 'NR == 1 {print $1}'
   )"
   test -n "$runner_service"
   sudo systemctl stop "$runner_service"
   ```

4. Review and apply Debian updates:

   ```bash
   sudo apt-get update
   apt list --upgradable
   sudo apt-get upgrade
   ```

5. Re-run the idempotent build-tool provisioner when its pinned versions or
   Debian prerequisites changed:

   ```bash
   sudo /opt/homelab-infrastructure/runners/linux/provision-build-tools.sh
   ```

6. Reboot if `/var/run/reboot-required` exists; otherwise start the service:

   ```bash
   sudo systemctl start "$runner_service"
   ```

7. Re-run both health checks and dispatch a representative trusted CI workflow.
   Confirm the job names `gha-linux-01` and completes successfully.

The GitHub runner normally updates itself. If its binary must be replaced
manually, prefer the replacement procedure below instead of modifying a
registered installation in place. Update the pinned version and digest in
`install-github-runner.sh` only through review and verify the GitHub-published
digest before use.

## Incident capture

If a job stalls, capture evidence before restarting anything:

```bash
runner_service="$(
  systemctl list-unit-files --type=service --no-legend \
    'actions.runner.*.service' | awk 'NR == 1 {print $1}'
)"
test -n "$runner_service"
sudo systemctl status "$runner_service" --no-pager
sudo journalctl -u "$runner_service" --since '-30 minutes' --no-pager
df -h /
df -h /home/runner/actions-runner/_work
free -h
ps -ef --forest
```

Preserve the affected GitHub run URL, job name, attempt number, timestamps, and
whether GitHub shows the runner as busy. Runner diagnostic logs are under
`/home/runner/actions-runner/_diag`; inspect them for the same time window, but
do not commit logs because they can contain repository or environment details.

After capture, restart only the smallest failing layer. Start with the runner
service; reboot the guest only if the service cannot recover or the operating
system requires it.

## Replace the production runner

Use a blue/green replacement so capacity and rollback remain available:

1. Clone VM 104 and let Proxmox/cloud-init generate new virtual hardware,
   machine, network, and SSH identities.
2. Bootstrap the clone and establish the final administrative authentication
   and sudo policy.
3. Install the pinned runner binary, but do not copy registration files from
   the production VM.
4. Register it with a unique temporary name in `trusted-ci` and with the five
   production labels.
5. Run the health checks and representative Python, Rust, PyO3, and wheel jobs.
6. Verify the new runner is idle, then stop its `actions.runner.*.service` unit
   on the old VM.
7. Keep the old VM powered off during a short rollback window. Rename the new
   runner only if the operational value outweighs the registration churn.
8. Generate a fresh removal token, unregister the old runner, and delete the
   retired VM only after the new runner has passed normal workloads.

If VM 104 is stale, first create a temporary maintenance clone, apply and
validate updates there, run `prepare-runner-template.sh`, and replace the
template only after confirming it contains no registration or clone-specific
identity. Never boot and modify the sole recovery template in place.
