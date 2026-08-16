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

> The manifests are the authority: [`manifest/home.txt`](manifest/home.txt) and
> [`manifest/system.txt`](manifest/system.txt) are what `bin/capture` and
> `bin/apply` actually read. The tables below mirror them and are grouped for
> reading rather than kept in manifest order. If they ever disagree, the
> manifests are right and the table is stale — fix the table.

**Tier 1 —** under `$HOME`, restored by `bin/apply`

| File | Divergence |
|------|-----------|
| `.config/hypr/hyprland.lua` | `OMARCHY_SCREENSHOT_DIR` into `Pictures/Screenshots`; workspaces 1/2 pinned to DP-1/DP-2 so the dashboard layout can rely on ws2; float rules for `krankulator` and `krengine` |
| `.config/hypr/monitors.lua` | Both scales forced to 1 — the panels are ~110 PPI, not HiDPI, and `gdk_scale = 2` doubled XWayland UIs. DP-1 pinned to `3440x1440@143.92` (`preferred` picks 100 Hz) at `y=510` to centre it against DP-2, which is rotated with `transform = 1` |
| `.config/hypr/looknfeel.lua` | `rounding = 8`; blur on (Omarchy ships it off) to pair with kitty's translucent background; `dwindle.split_width_multiplier = 0.85` so the portrait screen stacks instead of splitting into 720px columns |
| `.config/hypr/input.lua` | MX Master 3: `sensitivity = 0.1`, `accel_profile = "flat"` |
| `.config/hypr/bindings.lua` | `SHIFT+ALT+X` → `portrait-dashboard`; `SUPER+SHIFT+S` reclaimed from Google Maps for region capture; `PRINT` → `screenshot-all-monitors` |
| `.config/kitty/kitty.conf` | `background_opacity 0.85` + live-tuning binds; 5000-line scrollback; `ctrl+shift+f` scrollback fzf; `alt+1..9` tab jumps |
| `.config/kitty/font-size.conf` | `font_size 12.0`, included last so it beats the `9.0` that `omarchy display text size` writes into `kitty.conf`. Lets the desktop slider drive GTK and the bar without shrinking the terminal |
| `.config/omarchy/shell.json` | Bar layout and indicator set, `idle.screensaver = 150` / `idle.lock = 300`, Mullvad region |
| `.config/omarchy/shell.toml` | `[font] base-size = 12` |
| `.config/omarchy/branding/screensaver.txt` | "GLASSPANE" in place of the stock omarchy wordmark, set in Press Start 2P — see [Machine notes](#machine-notes) for how it was generated |
| `.config/omarchy/hooks/post-boot.d/gpu-rgb` | OpenRGB sets the GPU to the machine's warm gold; the only device `coolercontrold` cannot reach |
| `.config/git/config` | `user.name` / `user.email` appended to Omarchy's defaults |
| `.config/starship.toml` | Full custom powerline prompt, replacing Omarchy's four-line default |
| `.local/bin/portrait-dashboard` | Rebuilds the two-monitor window layout; replaces the Ubuntu-era `restore_desktop.sh` |
| `.local/bin/screenshot-all-monitors` | `grim` with no `-g`, to capture the whole layout in one image |
| `.config/rsnapshot/rsnapshot.conf` | Rolling hardlinked snapshots to the NAS. TAB-separated; `-rt` not `-a` because SMB cannot represent POSIX perms |
| `.config/rsnapshot/excludes` | Build output, caches, re-fetchable bulk, and secrets — `*.pem`/`*.key`/`.env` are matched *inside* included trees |
| `.config/systemd/user/rsnapshot@.service` | Runs one rsnapshot interval; `OnFailure=` wires the notifier |
| `.config/systemd/user/rsnapshot-failure@.service` | Desktop notification when a backup fails, so it is not silent |
| `.config/systemd/user/rsnapshot-alpha.timer` | 08/12/18/23 daily |
| `.config/systemd/user/rsnapshot-beta.timer` | daily 07:30 |
| `.config/systemd/user/rsnapshot-gamma.timer` | Mondays 07:00 |
| `.config/systemd/user/rsnapshot-delta.timer` | 1st of month 06:30 |
| `.config/wireplumber/wireplumber.conf.d/50-audio-endpoints.conf` | Distinct nicks for the Scarlett's two physical inputs (both shipped as "Scarlett Solo USB", so the menu showed the same name twice); NVIDIA HDMI output disabled |
| `.bashrc` | Restores GNU `ls` over Omarchy's eza alias (eza's `-s` breaks `ls -alstr`), repopulates `LS_COLORS`, moves eza to `ll`/`lla`/`llt`; sources `cargo/env` |

**Tier 2a —** root-owned files, copied to `system/`. Never auto-restored;
`bin/apply` will not touch these, so put them back deliberately.

| File | Notes |
|------|-------|
| `/etc/coolercontrol/config.toml` | Pump + fan curves; the daemon rewrites this itself |
| `/etc/modprobe.d/nvidia-power-management.conf` | `NVreg_PreserveVideoMemoryAllocations=1`. Deliberately *not* `nvidia.conf`, which Omarchy's installer overwrites. Needs the three nvidia sleep units enabled and the UKI rebuilt with `limine-mkinitcpio` |
| `/etc/udev/rules.d/99-wol-rtl8125.rules` | Lets the RTL8125 raise PCI wake events; matched by vendor:device because PCIe enumeration order shifts between boots |
| `/etc/udev/rules.d/70-vial.rules` | `uaccess` on the Vial HID interface, matched by Vial's magic serial rather than blanket hidraw access |
| `/etc/systemd/system/systemd-suspend.service.d/20-freeze-user-sessions.conf` | Re-enables `SYSTEMD_SLEEP_FREEZE_USER_SESSIONS`, which nvidia-utils turns off. Without it Wayland clients keep issuing GPU work while the driver suspends, the fences never signal, and kitty blocks ~5s on resume |
| `/etc/modules-load.d/vmware.conf` | `vmw_vmci` + `vmw_vsock_vmci_transport`; in-tree modules nothing else loads, without which VMware cannot open `/dev/vmci` |

**Tier 2b —** inventories regenerated by `bin/capture`. Not config — these
record what to reinstall, and are read by a human, not a script.

| File | Source |
|------|--------|
| `system/packages/pacman-explicit.txt` | `pacman -Qqen` |
| `system/packages/aur-explicit.txt` | `pacman -Qqem` |
| `system/systemd/enabled-units.txt` | enabled system units |
| `system/systemd/enabled-units-user.txt` | enabled user units |
| `system/etc/fstab.reference` | **reference only** — never restore; UUIDs are disk-specific |

## Machine notes

**Backups.** rsnapshot to the Synology (`blackbox`) over SMB, mounted on demand
at `/mnt/blackbox` via an `x-systemd.automount` entry in `/etc/fstab` with
credentials in `/etc/samba/credentials-blackbox` (mode 600, not tracked).

Every snapshot is a complete browsable directory tree; unchanged files are
hardlinks to the previous snapshot, so N snapshots of a ~875MB set cost little
more than 875MB. Verified: two snapshots, same inode, `du` of both together
equals one. Browse them in File Station under `Backups/glasspane/alpha.0`,
`alpha.1`, `beta.0` … newest is always `.0`.

Retention mirrors the Back In Time policy from Ubuntu: all snapshots for ~2
days, then daily for 7, weekly for 4, monthly for 24.

Why SMB rather than SSH or the rsync daemon — all three were tried:

- **SSH** authenticates fine (the key works, PAM opens a session) but DSM then
  refuses every command with `Permission denied, please try again`, because it
  restricts SSH to the `administrators` group. Synology's position is that SSH
  access *is* admin access.
- **DSM's rsync service** (port 873) never started listening despite being
  enabled with an account, and did not create the `NetBackup` share its own
  documentation describes.
- **SMB** works, and — the load-bearing question — **hardlinks work over it**,
  which is what makes the whole snapshot model viable. Tested before building
  anything on the assumption.

The mount is `nounix`/`forceuid`, so POSIX permissions and ownership are not
preserved. That is why the config uses `-rt` rather than `-a`; with `-a` every
run would churn and log errors forever.

`no_create_root 1` makes rsnapshot refuse to run when the NAS is absent, rather
than quietly writing a "backup" to the local disk that protects nothing.

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

**Screensaver wordmark.** The screensaver is `ttfx` animating a text file, so
what you see is art made of Unicode block glyphs, not type — it renders in
whatever font the terminal already has, and no font needs to be installed. The
committed `branding/screensaver.txt` was made once, like this:

```bash
# Press Start 2P from https://fonts.google.com/specimen/Press+Start+2P (OFL)
magick -font PressStart2P-Regular.ttf -pointsize 8 +antialias \
  -background none -fill black label:GLASSPANE -trim +repage /tmp/wm.png
magick identify /tmp/wm.png                      # -> 71x7
omarchy transcode ascii /tmp/wm.png ~/.config/omarchy/branding/screensaver.txt \
  --mode block --no-trim --width 71 --height 4   # height = ceil(7 / 2)
```

Three things matter and none are obvious:

- **`-pointsize 8 +antialias`.** The face is drawn on an 8px grid, so at size 8
  with antialiasing off one font pixel is one image pixel. Any other size leaves
  half-lit edges that threshold unevenly, and stems come out 1px on one stroke
  and 2px on the next.
- **Exact `--width`/`--height`.** `transcode ascii` runs `-resize` against the
  box it is given, and `-resize` scales *up* to fit as well as down. Passing the
  bitmap's own dimensions makes it a no-op; the defaults (80x26) would scale a
  71x7 bitmap by 1.14 and wreck the pixel grid. `--height` is in text rows, and
  block mode packs two pixel rows into one.
- **Stay under ~88 columns.** That is what DP-2 shows at the screensaver's
  `font_size 18` in portrait. Wider is fine on the ultrawide and clips there.
  Omarchy's own `logo.txt` is 81 wide.

Inverting it — light field, knocked-out letters — does not work at this size.
1px strokes at a 7px cap height fill in when inverted. The braille mode has
roughly twice the resolution for the same screen area and can carry it.

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
