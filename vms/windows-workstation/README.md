# Windows 11 lab workstation

VM 105, `win11-lab-workstation`, is a dedicated interactive sandbox on
`pve05`. It is separate from `win-jump` and from all CI runners.

## VM profile

- Windows 11 Pro 25H2 installation media
- 8 host-type vCPUs in one socket
- 24 GiB fixed memory with ballooning disabled
- 256 GiB thin-provisioned VirtIO SCSI system disk on `local-lvm`
- Q35 machine type and OVMF UEFI
- Microsoft Secure Boot keys and virtual TPM 2.0
- VirtIO network adapter on `vmbr0`
- QEMU guest-agent integration enabled
- Windows and VirtIO driver ISOs attached during installation
- no GPU passthrough

## Physical USB map

The host has one USB controller shared with internal Bluetooth, so the
controller must remain host-owned. Individual external port paths are passed
to the VM instead. Each USB 3 connector has both its SuperSpeed path and USB 2
companion path attached.

| Physical connector | USB 3 path | USB 2 path | VM mappings |
| --- | --- | --- | --- |
| Front left USB 3.2 | `2-1` | `1-1` | `usb0`, `usb1` |
| Front right USB 3.2 | `2-9` | `1-2` | `usb2`, `usb3` |
| Rear USB 3.2 A | `2-3` | `1-5` | `usb4`, `usb5` |
| Rear USB 3.2 B | `2-4` | `1-6` | `usb6`, `usb7` |
| Rear USB 2 ordinary | n/a | `1-4` | `usb8` |
| Rear USB 2 Smart Power On | n/a | `1-3` | `usb9` |

Internal Intel Bluetooth remains host-owned at `1-14`. The Realtek USB
2.5 GbE adapter formerly occupying rear USB 3.2 B was unused and was removed.
The onboard NIC remains the host's management and Corosync interface.

## Installation handoff

At the Windows disk-selection page, load the VirtIO SCSI driver from the
VirtIO ISO under `vioscsi\w11\amd64` so the 256 GiB disk becomes visible.
After Windows starts, install the VirtIO network driver and QEMU guest agent;
the VirtIO guest-tools installer can supply the complete supported driver set.

After installation:

1. Apply Windows updates and confirm Device Manager has no unexpected devices.
2. Confirm the QEMU guest agent reports an IP address to Proxmox.
3. Enable RDP for trusted LAN or VPN access and retain Windows Firewall.
4. Confirm USB 2 and USB 3 hot-plug behavior on the mapped external ports.
5. Remove the Windows ISO from the boot order when installation is complete.
6. Create a clean baseline snapshot or backup before sandbox use.
