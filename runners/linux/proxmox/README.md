# Proxmox VM profile

This profile captures the validated virtual hardware for a Linux GitHub
Actions runner. Values that identify a particular guest or network are
intentionally omitted.

## Validated hardware

| Setting | Value |
| --- | --- |
| Guest OS | Debian 13 x86-64 |
| CPU type | `host` |
| Sockets | 1 |
| Cores | 4 |
| Memory | 8192 MiB, fixed |
| System disk | 120 GiB SCSI |
| SCSI controller | `virtio-scsi-single` |
| Disk options | discard, I/O thread, SSD emulation |
| Network adapter | VirtIO, firewall enabled |
| QEMU guest agent | enabled |
| Boot order | system disk, then network |

Eight GiB of memory is sufficient for the currently validated Python, Rust,
PyO3, and wheel-building workloads. Increase CPU or memory only after measuring
guest pressure during representative CI jobs.

## Apply the hardware profile

Create the VM and system disk using the selected installation or cloud-image
workflow, then apply the reusable settings. Replace the shell variables with
values appropriate for the target Proxmox node:

```bash
qm set "$VM_ID" \
  --agent enabled=1 \
  --balloon 0 \
  --boot order=scsi0\;net0 \
  --cores 4 \
  --cpu host \
  --memory 8192 \
  --net0 virtio,bridge="$BRIDGE",firewall=1 \
  --numa 0 \
  --ostype l26 \
  --scsihw virtio-scsi-single \
  --sockets 1

qm set "$VM_ID" \
  --scsi0 "$STORAGE:vm-$VM_ID-disk-0,discard=on,iothread=1,ssd=1"
```

Do not copy a MAC address, SMBIOS UUID, VM generation ID, machine ID, SSH host
keys, or GitHub runner identity between guests. Proxmox should generate the
virtual hardware identifiers, and each clone must receive fresh operating
system and runner identities.

## Provisioning boundary

The reusable VM layer should install the base operating system, QEMU guest
agent, administrative and service accounts, and the build toolchain. GitHub
runner download and registration remain a separate post-clone operation so no
registration token or runner credential is captured in a template.
