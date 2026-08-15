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
- **Fan curves are driven by Kraken liquid temperature, not CPU temperature.**
  Coolant is thermally damped, so fans do not chase momentary CPU spikes.
  Do not "fix" this back to a CPU source.
- **`/etc/fstab` is reference only.** UUIDs are machine-specific; never restore
  it onto another machine.
- The old `dotfiles` and `scripts` repos in `~/Documents/code/` are **Ubuntu-era
  and retired.** Read them for history; do not reintroduce their GNOME,
  VMware, or `yoda` cooling machinery.
