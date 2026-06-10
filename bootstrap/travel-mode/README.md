# Travel mode

Take the homelab to a friend's house, plug into their router, watch Plex on
your Apple TV 4K. Reverse when home.

## What it does

| Resource | Home mode | Travel mode |
|----------|-----------|-------------|
| PVE host vmbr0 | static `10.0.0.19/24` | DHCP |
| Media LXC (104) | static `10.0.0.161/24` | DHCP |
| k3s VMs (100/101/102) | running, autostart | stopped, no autostart |
| Pi-hole LXC (103) | running, autostart | stopped, no autostart |
| Ollama LXC (105) | running, autostart | stopped, no autostart |
| Torrent compose stack | running on media LXC | stopped (manual restart at home) |

Only Plex + Docker engine stay up at friend's house. Everything else parked.

## Install (one-time, from workstation)

```bash
cd bootstrap/travel-mode
./install.sh
```

Pushes:
- `/usr/local/sbin/travel-mode-on`
- `/usr/local/sbin/travel-mode-off`
- `/usr/local/share/travel-mode/interfaces.{home,travel}`

## Before leaving home

```bash
ssh pve travel-mode-on
ssh pve poweroff
```

Unplug ethernet, transport host, plug into target router's LAN port, power on.

Host boots on DHCP. Media LXC autostarts on DHCP. Plex announces new IP to
plex.tv. Apple TV 4K (signed into your Plex account) re-discovers server.

## After returning home

Plug into home network, power on. Host boots in **travel mode** still (DHCP),
gets some 10.0.0.x IP from home router (within the DHCP range, not the static
.19).

Find it via:
- mDNS: `ping pve.local` (if avahi running)
- Router admin UI
- `arp-scan 10.0.0.0/24` from workstation

Then:

```bash
ssh root@<dhcp-ip> travel-mode-off
```

Script restores static config + reboots. Host comes back at `10.0.0.19`. All
workloads autostart.

Torrent stack is intentionally **not** auto-restarted (gluetun could pause
mid-trip and leak; safer to bring up manually). To restart:

```bash
ssh root@10.0.0.161 'cd /opt/torrents && docker compose up -d'
```

## Why scripts and not autodetect

Manual gates = predictable state machine. You always know whether the host
thinks it's home or away. Autodetect (DHCP-with-static-fallback) is clever
but fails confusingly when DHCP server is slow.

## Files

- `interfaces.home` — snapshot of static `/etc/network/interfaces`
- `interfaces.travel` — DHCP variant (no address/gateway lines)
- `travel-mode-on` — PVE-side script: stop workloads + swap config
- `travel-mode-off` — PVE-side script: restore config + reboot
- `install.sh` — workstation-side script: push files to PVE
