# Common node configuration

Configuration in this directory is intended for Proxmox hosts after initial
key-based access has been verified.

## Key-only SSH administration

The `sshd_config.d/60-key-only-admin.conf` drop-in keeps public-key login
enabled and disables password and keyboard-interactive authentication. Root
login remains available with a key so Proxmox nodes can be administered
without storing an administrative password in automation.

Before installing the drop-in, add and test an authorized public key in a
separate SSH session. Install the file and validate the complete SSH
configuration before reloading the service:

```bash
install -o root -g root -m 0644 \
  nodes/common/sshd_config.d/60-key-only-admin.conf \
  /etc/ssh/sshd_config.d/60-key-only-admin.conf
sshd -t
systemctl reload ssh
```

Keep the original session open until a fresh key-only connection succeeds.
Confirm the effective settings with:

```bash
sshd -T | grep -E \
  '^(permitrootlogin|passwordauthentication|kbdinteractiveauthentication|pubkeyauthentication)'
```

OpenSSH may report `without-password` for `PermitRootLogin`; it is the
effective synonym for `prohibit-password`.
