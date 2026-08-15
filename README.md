# mymarchy

Configuration for **glasspane** — an Omarchy (Arch + Hyprland) workstation,
migrated from Ubuntu 26.04.

This is not a portable dotfiles collection. It captures the state of one
specific machine, including hardware-dependent settings like monitor geometry
and cooling curves.

> Agents working on this machine: read [AGENTS.md](AGENTS.md) first.

## Why this exists

Omarchy ships good defaults in `/usr/share/omarchy/` and loads your overrides
from `~/.config/` on top. That means the interesting information is not "my
config" but **"the small set of places where I diverged from the defaults"** —
plus a handful of root-owned files that live outside `$HOME` entirely.

This repo tracks exactly that, and nothing else.

## Design

Three tiers, split by who owns the file:

| Tier | What | Where | Restored by |
|------|------|-------|-------------|
| 1 | User config that differs from Omarchy's default | `home/` | `bin/apply` |
| 2 | Root-owned config, package lists, enabled units | `system/` | by hand, deliberately |
| 3 | Provisioning steps | `bin/apply` output | by hand |

Two rules do most of the work:

**Only track what diverges.** If a file matches `/usr/share/omarchy/config/`,
it is not tracked. Tracking an unmodified override file would pin you to today's
defaults and quietly block upstream improvements. `bin/check` flags tracked
files that have drifted back to matching the default.

**Copy, don't symlink.** Stow was considered and rejected: Omarchy's update
migrations edit config with `sed -i`, which replaces a symlink with a regular
file rather than writing through it. Symlinks would detach silently on some
future `omarchy update`. Copying is less elegant and far more durable — and
`bin/check` covers the one weakness, by making "I forgot to capture" visible.

## Usage

```bash
bin/check      # has the live system drifted from the repo?
bin/capture    # pull live state into the repo (run after any config change)
bin/apply      # push the repo onto a machine (fresh install; backs up first)
bin/apply --dry-run
```

Typical loop:

```bash
# ... change something in ~/.config ...
bin/capture
git diff          # review
git commit -am "hypr: pin DP-1 to 144Hz"
```

## Tracking a new file

1. Confirm it actually differs from the Omarchy default:
   ```bash
   diff /usr/share/omarchy/config/<path> ~/.config/<path>
   ```
2. Add the `$HOME`-relative path to `manifest/home.txt`
   (or the absolute path to `manifest/system.txt` for root-owned files).
3. Run `bin/capture` and commit.

## What's tracked today

**Tier 1 —** `~/.config/`

| File | Divergence |
|------|-----------|
| `hypr/monitors.lua` | DP-1 pinned to `3440x1440@143.92`; DP-2 rotated portrait |
| `hypr/looknfeel.lua` | `rounding = 8` |
| `kitty/kitty.conf` | `font_size 11` |
| `omarchy/shell.json` | bar/shell configuration |
| `git/config` | identity and aliases |

**Tier 2 —** root-owned

| File | Notes |
|------|-------|
| `/etc/coolercontrol/config.toml` | pump + fan curves; daemon rewrites this itself |
| `packages/pacman-explicit.txt` | `pacman -Qqen` |
| `packages/aur-explicit.txt` | `pacman -Qqem` |
| `systemd/enabled-units.txt` | enabled system units |
| `etc/fstab.reference` | **reference only** — never restore; UUIDs are disk-specific |

## Machine notes

**Cooling.** An NZXT Kraken X-series pump, an NZXT RGB & Fan Controller
(3 fans), and an ASUS Aura LED controller, all managed by
[CoolerControl](https://docs.coolercontrol.org/). `coolercontrold` is enabled
and re-applies settings on boot and after resume, which is why the Ubuntu-era
`yoda` daemon and its custom boot/resume services were retired.

- Pump: fixed 60%. Deliberately not a curve — AIO cooling saturates well below
  full pump speed, and a *varying* pump tone is more distracting than a
  slightly louder constant one.
- Fans: driven by **liquid temperature**, not CPU temperature. Coolant has
  enormous thermal mass, so it ignores momentary CPU spikes and the fans stay
  calm. Curve: flat 25% to 32 °C, then 35 °C→35%, 38 °C→50%, 41 °C→70%,
  45 °C→100%.
- `nzxt_kraken3` is **not** blacklisted; it does not block control.

## Manual steps, not captured as files

Some settings deliberately are not tracked, either because the file is
machine-specific or because it holds a secret. Reproduce these by hand on a
rebuild.

**Wake-on-LAN.** Lives in the NetworkManager connection profile as
`wake-on-lan=64` (`0x40` = MAGIC). The profile is not tracked because it carries
a machine-specific UUID and MAC binding, the same reason `fstab` is
reference-only. The tracked udev rule only permits PCI wake events — without
this the NIC is never armed and Wake-on-LAN silently does nothing:

```bash
nmcli connection modify "Wired connection 1" 802-3-ethernet.wake-on-lan magic
# verify
ethtool eno1 | grep -i wake-on          # expect: Wake-on: g
```

BIOS needs `Power On By PCI-E` enabled and `ErP Ready` disabled. On this
machine they already are — Wake-on-LAN worked under Ubuntu on the same
hardware.

**Windows VM.** `~/.config/windows/docker-compose.yml` is not tracked: Omarchy's
installer writes the account password into it inline, and it is regenerated
world-readable on every reinstall. Set it to `600` after any reinstall. Current
shape:

```
VERSION 11 · RAM_SIZE 16G · CPU_CORES 2 · DISK_SIZE 64G · TZ Europe/Stockholm
```

VM data in `~/.windows`, shared folder `~/Windows`, ports bound to localhost
only (`8006` noVNC, `3389` RDP). Prefer RDP over noVNC for real use:

```bash
xfreerdp3 /v:127.0.0.1:3389 /u:anders /dynamic-resolution /sound /clipboard
```

## History

The Ubuntu-era `dotfiles` and `scripts` repos in `~/Documents/code/` are
retired. They remain useful as history, but their GNOME extensions, VMware
config, `restore_desktop.sh`, and `yoda` cooling stack do not apply to Omarchy.
