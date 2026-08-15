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

**Windows VM — using VMware, not Dockur.** The punch list planned to run
Windows (for MTGO) under Omarchy's Dockur/`dockurr/windows` setup and retire
VMware. That was tried and abandoned: **the RDP session hung frequently**, which
is disqualifying for something you sit in for hours. VMware is the choice
instead.

Do not treat this as an unfinished migration and reinstall Dockur. If it is
ever revisited, the thing to fix is the RDP hangs, not the installation.

Removed: the `omarchy-windows` container, `~/.windows` (the VM disk), and
`~/.config/windows`. `~/Windows` remains as an empty shared folder.

Two things worth carrying over if Dockur is ever retried:

- Its `docker-compose.yml` holds the Windows account password inline and is
  regenerated **world-readable** on every reinstall. `chmod 600` it, or move the
  secret to a `600` `.env` — noting that `docker compose` only reads `.env` from
  the project directory, so it must be run from `~/.config/windows`. Running it
  elsewhere resolves `${PASSWORD}` to empty, which produced a Windows account
  with a blank password and a login that shut down on sight.
- The installer defaults to `CPU_CORES: 2`, well below what this machine can
  give it.

**Installing `vmware-workstation`.** It is in `system/packages/aur-explicit.txt`
and its two services are in `system/systemd/enabled-units.txt`, but neither
`bin/apply` nor pacman will get it running on its own:

```bash
yay -S vmware-workstation
sudo systemctl enable --now vmware-networks vmware-usbarbitrator
lsmod | grep -E 'vmmon|vmnet'      # expect both loaded
dkms status | grep vmware          # modules built against the running kernel
```

The services are what load `vmmon`/`vmnet`; installing the package alone leaves
them disabled and the modules unloaded.

If the install fails with

```
error: failed to commit transaction (conflicting files)
vmware-workstation: /etc/vmware-installer/database exists in filesystem
```

then a previous attempt left `/etc/vmware-installer/` behind. It is orphaned —
`pacman -Qo` reports no owner — and pacman refuses to overwrite files it does
not own. Remove the directory and reinstall; it is only the installer's own
state database and gets recreated. Answer **N** to yay's "Packages to
cleanBuild?" prompt: the failure is at pacman's install stage, well after a
successful compile, so rebuilding wastes time.

## History

The Ubuntu-era `dotfiles` and `scripts` repos in `~/Documents/code/` are
retired. They remain useful as history, but their GNOME extensions, VMware
config, `restore_desktop.sh`, and `yoda` cooling stack do not apply to Omarchy.
