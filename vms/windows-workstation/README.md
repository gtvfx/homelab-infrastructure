# Windows 11 lab workstation

VM 105, `win11-lab-workstation`, is a dedicated interactive sandbox on
`pve05`. It is separate from `win-jump` and also provides the homelab's
current trusted Windows CI capacity.

## VM profile

- Windows 11 Pro 25H2 installation media
- 8 host-type vCPUs in one socket
- 24 GiB fixed memory with ballooning disabled
- 256 GiB thin-provisioned VirtIO SCSI system disk on `local-lvm`
- Q35 machine type and OVMF UEFI
- Microsoft Secure Boot keys and virtual TPM 2.0
- VirtIO network adapter on `vmbr0`
- QEMU guest-agent integration enabled
- Windows and VirtIO driver ISOs attached during installation, then ejected
- no GPU passthrough
- disk-only boot order after installation

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

Windows 11 Pro installation and VirtIO guest-tools installation were completed
on 2026-10-04. The QEMU guest agent reports successfully to Proxmox. RDP is
enabled with Network Level Authentication and its Windows Firewall rules are
restricted to the trusted LAN subnet. The endpoint is reachable from the Codex
workstation. The normal Windows update loop is complete; an optional preview
cumulative update was intentionally deferred.

Interactive RDP sign-in was subsequently validated with a password-protected
local administrator account. The private account and host identifiers are not
recorded in this public repository.

A signed RDP profile was also validated with both monitors, clipboard sharing,
local audio, NLA, and unnecessary device redirection disabled. The signing and
endpoint certificate identifiers remain private.

Windows OpenSSH Server provides the non-interactive administration channel.
It starts automatically, is restricted to the designated local administrator,
and accepts the Codex host's existing Ed25519 public key. Password and
keyboard-interactive authentication are disabled. Its firewall rule applies
only to the Private profile and trusted LAN. Key login, rejection without a
public key, stable-name access, and WinGet visibility in the administrator's
user context were verified after hardening. Keep the QEMU guest agent enabled
as an independent recovery path.

During a stopped maintenance cycle on 2026-10-04, the boot order was reduced
to the VirtIO system disk. Snapshot `baseline-2026-10-04` captured the system,
EFI, and TPM disks. An independent compressed full backup completed on shared
Synology storage with a final archive size of 38.76 GB. The VM then booted
successfully, and its QEMU guest agent and VirtIO network interface returned.

## Configuration-as-code direction

Use a reviewed WinGet Configuration document backed by PowerShell DSC for the
initial workstation software baseline. Candidate packages include PowerShell,
Windows Terminal, Git, GitHub Copilot CLI, required Visual C++ redistributables,
and deliberately selected .NET runtime or SDK major versions.

Keep interactive authentication out of configuration files. Start with manual,
reviewed upgrades instead of an unattended blanket upgrade. Puppet is deferred
until the Windows fleet or drift-remediation requirements justify its server,
agent, certificate, catalog, and module lifecycle.

The initial v3 configuration is [`configuration.winget`](configuration.winget).
It manages the latest release within this reviewed package set:

- PowerShell 7;
- Windows Terminal;
- Git for Windows;
- GitHub Copilot CLI;
- x64 and x86 Visual C++ v14 redistributables; and
- the .NET 10 SDK, which includes the matching runtime.

The explicit .NET major version prevents a future major release from entering
the baseline automatically. Copilot authentication remains an interactive,
per-user step and is not represented in the configuration.

Review the file before every application, then test it before allowing changes:

```powershell
dsc config test --file .\configuration.winget
dsc config set --file .\configuration.winget
```

Reapplying the configuration updates only its declared packages. It does not
replace Windows Update and does not perform a blanket upgrade of other
applications.

WinGet `1.29.380` incorrectly reported its native `Microsoft.WinGet/Package`
resource as unavailable when running `winget configure validate`, including
for a v3 document exported by WinGet itself. The underlying DSC v3 resource is
installed, publicly discoverable, and exposes a valid schema, so use the native
DSC `test` and `set` commands above until the WinGet validator is corrected.

The baseline was first applied on 2026-10-04. A second `dsc config test`
reported all seven resources in the desired state with no errors or differing
properties. Executable checks from a fresh SSH session confirmed PowerShell
`7.6.6`, Git `2.55.0.windows.5`, Copilot CLI `1.0.91`, and .NET SDK `10.0.401`.

## GitHub Actions runner

WINLAB replaced the retired bare-metal `MINI-PC` organization runner on
2026-10-04. GitHub Actions runner `2.337.0` is installed under
`C:\actions-runner` and registered as `WINLAB` in the `trusted-ci` runner
group. Its labels are `self-hosted`, `Windows`, `X64`, `windows-11`, and `ci`.

The generated `actions.runner.gtvfx-envoy.WINLAB` Windows service starts
automatically under `NT AUTHORITY\NETWORK SERVICE`; it does not use the
interactive RDP administrator's identity or profile. The machine-wide
PowerShell execution policy is `RemoteSigned`, which permits the local setup
scripts used by GitHub Actions while continuing to block unsigned scripts that
retain a downloaded-file mark.

Python 3.11.9 is pre-provisioned in the runner tool cache from the official
`actions/python-versions` archive with its published checksum verified. This
allows `actions/setup-python` to select the required interpreter without
granting the runner service administrative privileges for dynamic installs.
PowerShell `7.6.6` is also installed machine-wide from the checksum-verified
official MSI so `pwsh` is available to the service; the interactive WinGet
package alone exposed only a user-profile WindowsApps shim.
Visual Studio Build Tools 2022 `17.14.41` supplies the recommended C++ build
workload. The x64 compiler and `vcvarsall.bat` were verified before the runner
service returned to production.
The machine PATH includes the machine-wide PowerShell and Git Bash directories
because composite actions resolve their shells from the runner service's
startup environment rather than an interactive user's profile.

Despatch's four pinned Envoy bundles are staged in a read-only local CI cache
under `C:\ci\envoy\bndl`. Its `ENVOY_STUDIO_BNDLS` repository variable points
to that cache. This avoids granting the service an interactive user's SMB
credentials or making CI availability depend on a mapped network share. Treat
the cache as replaceable input and refresh it deliberately when the Stack's
bundle pins change.

The runner archive was downloaded from the official `actions/runner` release
and verified against its GitHub-published SHA-256 digest before extraction.
The short-lived organization registration token was piped directly into the
remote registration process and is not stored in this repository.

This is an intentional shared-role VM, so a trusted workflow can affect the
same operating system used as the interactive sandbox. Keep repository access
restricted through `trusted-ci`, require the `windows-11` and `ci` labels on
static self-hosted Windows jobs, and do not expose the runner to unreviewed
fork code. The pre-runner baseline snapshot and full backup remain the clean
recovery boundary.

After installation:

1. Confirm Device Manager has no unexpected devices.
2. Confirm USB 2 and USB 3 hot-plug behavior on the mapped external ports.
3. Build and review the WinGet Configuration baseline before applying it.
4. Keep Windows Update responsible for the operating system and security fixes.
