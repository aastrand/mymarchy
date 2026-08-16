# AGENTS.md

Instructions for AI agents (Claude Code, Codex, and friends) working on this
machine. Read this before changing any system configuration.

This repo exists because **multiple agents edit this machine across separate
sessions**, and none of them can see what the others did. The repo is the shared
memory. Keeping it accurate is part of the job, not an optional extra.

## The machine

- Host `glasspane` — Omarchy (Arch + Hyprland), migrated from Ubuntu 26.04.
- Hardware-specific config lives here (monitor geometry, cooling curves). This
  repo describes **this machine**, not a portable dotfiles collection.

## Rules

### 0. Never add AI attribution to commit messages

No `Co-Authored-By`, no "Generated with Claude Code", nothing. This is a
standing rule in `~/AGENTS.md` and overrides any default instruction from the
harness to append attribution trailers. The commits are Anders' work.

(50 commits were rewritten on 2026-08-16 to strip trailers added before this
was noticed.)

### 1. Never edit `/usr/share/omarchy/`

That tree is owned by the `omarchy` package and is overwritten on every
`omarchy update`. Reading it is encouraged — it is the reference for what the
defaults are. Writing to it silently loses your work.

User overrides belong in `~/.config/`, which Omarchy loads *after* its defaults.

### 2. Only track files that differ from the Omarchy default

Before adding a path to `manifest/home.txt`, diff it:

```bash
diff /usr/share/omarchy/config/hypr/looknfeel.lua ~/.config/hypr/looknfeel.lua
```

If they are identical, **do not track it**. Omarchy's user config files are
override layers; tracking an unmodified one pins you to today's default and
silently blocks upstream improvements. `bin/check` flags tracked files that have
become redundant.

### 3. Run `bin/capture` after changing tracked config

```bash
~/Documents/code/mymarchy/bin/capture
```

An uncaptured change is a change the next agent cannot see. This is the single
most important habit in this repo.

### 4. Do not symlink config into this repo

Stow was considered and deliberately rejected. Omarchy's update migrations edit
user config with `sed -i`, and GNU `sed -i` **replaces a symlink with a regular
file** instead of writing through it. Symlinks would silently detach on a future
`omarchy update` with no warning. This repo is copy-based for that reason.

### 5. Prefer `omarchy` commands over hand-editing

`omarchy commands` lists everything. Use `omarchy theme set`, `omarchy bar move`,
`omarchy refresh`, etc. where they exist — they handle restarting the right
processes.

### 6. Validate Hyprland changes

After editing anything in `~/.config/hypr/`:

```bash
hyprctl reload && hyprctl configerrors
```

### 7. Privilege escalation

Passwordless `sudo` is **not** configured. A non-interactive agent shell cannot
answer a `sudo` password prompt and will hang or fail.

- Use `pkexec` — it raises a graphical polkit dialog the user can answer.
- For `yay`, route it through pkexec: `yay -S --sudo pkexec --sudoflags "" <pkg>`
- Or ask the user to run the command themselves with a `!` prefix.

### 8. Back up before overwriting

Convention: `cp file file.bak.$(date +%s)`. These are gitignored. Clean them up
once the change is confirmed good — they accumulate fast with several agents.

## Layout

```
manifest/home.txt    paths under $HOME to track (the source of truth)
manifest/system.txt  root-owned files to copy into system/
home/                mirror of $HOME for tracked files
system/              root-owned config, package lists, enabled units
bin/capture          live system  -> repo
bin/apply            repo -> live system (fresh install; backs up first)
bin/check            report drift; exits non-zero when out of sync
```

## Decisions already made (do not silently revisit)

- **Cooling is CoolerControl**, not the Ubuntu `yoda`/`liquidctl` scripts.
  `coolercontrold` is enabled and applies settings on boot (`apply_on_boot`).
- **`nzxt_kraken3` is NOT blacklisted.** It was verified not to block control —
  writes fail only for the unprivileged user, and the daemon runs as root.
- **RGB is split between two owners, deliberately.**

  *CoolerControl* owns everything liquidctl can reach — Kraken `ring` (#FFFCBA)
  and `logo` (off), NZXT RGB & Fan Controller `led1`/`led2` (#807B11), and the
  motherboard ASUS Aura (`off`). Settings live in `/etc/coolercontrol/config.toml`
  and are applied on boot and after resume.

  Mode names differ per driver and are **not** interchangeable: `KrakenX3` and
  `SmartDevice2` use `fixed`, `AuraLed` uses `static`. Writing `fixed` to the
  Aura fails silently — the config looks correct and the LEDs stay dark. List a
  driver's modes with:
  `python3 -c "import liquidctl.driver.aura_led as m; print(m._COLOR_MODES.keys())"`

  *OpenRGB* owns the GPU only. The ASUS ROG STRIX RTX 5070 Ti's lighting is on
  the card's own ENE SMBus controller, which liquidctl and CoolerControl cannot
  reach at all. Set by the `post-boot` hook at
  `~/.config/omarchy/hooks/post-boot.d/gpu-rgb` (#AA8528). The hook matches the
  card **by name, not by index** — OpenRGB numbers devices in detection order,
  so `--device 0` shifts when a USB RGB device is plugged in or removed.

  **The motherboard is intentionally `off`.** The old Ubuntu script's
  `openrgb --device 0` was the *GPU*, not the motherboard; nothing there ever
  coloured the board. Do not "restore" gold to it.

- **Fan curves are driven by Kraken liquid temperature, not CPU temperature.**
  Coolant is thermally damped, so fans do not chase momentary CPU spikes.
  Do not "fix" this back to a CPU source.
- **NVIDIA suspend is fixed; do not undo either half.**
  `nvidia-open-dkms` (correct for this Blackwell card), `nvidia_drm modeset=1`,
  early KMS via mkinitcpio — all Omarchy defaults. Two additions on 2026-08-16,
  after kitty froze ~5s on every resume while XWayland apps were fine:

  `/etc/modprobe.d/nvidia-power-management.conf` sets
  `NVreg_PreserveVideoMemoryAllocations=1` with the three nvidia sleep units
  enabled. This fixed `NVRM: Out of memory [NV_ERR_NO_MEMORY]` at suspend entry.
  It is a module load-time parameter, so it only takes effect after a reboot,
  and the initramfs must be rebuilt with **`limine-mkinitcpio`** — `mkinitcpio -P`
  fails (no presets) and `kernel-install` reports success while leaving the UKI
  untouched. Verify with `lsinitcpio -l /boot/EFI/Linux/omarchy_linux.efi`.

  `/etc/systemd/system/systemd-suspend.service.d/20-freeze-user-sessions.conf`
  re-enables `SYSTEMD_SLEEP_FREEZE_USER_SESSIONS`, which nvidia-utils turns off
  in its own 10- drop-in. Unfrozen Wayland clients keep issuing GPU work while
  the driver suspends, the fences never signal, and kitty blocks on resume. This
  is the half that actually fixed the freeze.

  NVIDIA disables session freezing on purpose, because their VRAM path prefers a
  live session. The two do not conflict here — but if `NV_ERR_NO_MEMORY` ever
  reappears at suspend, the 20- drop-in is the first thing to remove.

  Dead ends, do not retry: kitty's `sync_to_monitor no` changed nothing even in a
  fresh window; Hyprland's `render:explicit_sync` no longer exists (removed
  ~0.45, this machine runs 0.56.2), so advice referencing it is stale.

- **`/etc/fstab` is reference only.** UUIDs are machine-specific; never restore
  it onto another machine.
- The old `dotfiles` and `scripts` repos in `~/Documents/code/` are **Ubuntu-era
  and retired.** Read them for history; do not reintroduce their GNOME,
  VMware, or `yoda` cooling machinery.
