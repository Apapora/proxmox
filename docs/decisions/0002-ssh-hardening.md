# 2. SSH hardening on the Proxmox host

Date: 2026-05-20
Status: Accepted

## Context

PVE 9 default sshd_config permits password auth, including root with a
password. The host is on a private LAN but the principle of "machines I
manage should be reachable only via keys I control" applies regardless. The
host needs to remain physically recoverable if I lose my key.

## Decision

Apply a drop-in at `/etc/ssh/sshd_config.d/99-hardening.conf`:

```
PermitRootLogin prohibit-password
PasswordAuthentication no
PubkeyAuthentication yes
PermitEmptyPasswords no
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
```

Use `systemctl reload ssh` (not restart) so existing sessions stay open during
the change. Validate with `sshd -t` before reload.

Drop-in chosen over editing the main file: survives package upgrades that
may overwrite `/etc/ssh/sshd_config`.

## Consequences

- SSH from any non-key-bearing machine is blocked. Acceptable — physical
  console + web UI still allow password recovery.
- This config will be re-applied via Ansible once Phase 3 lands. The current
  manual placement is the bootstrap state.
- 2FA via SSH not configured (deferred). PVE web UI 2FA is independent and
  can be enabled separately.
