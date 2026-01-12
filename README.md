# virtual-insanity (Gentoo extreme gaming stack)

This repo is a **hands-free Gentoo installer** meant to be run from a Gentoo live USB (UEFI) and produce a system tuned for:
- **gaming + general use**
- **LLVM/Clang toolchain**, ThinLTO, sample-PGO (AutoFDO-style via SPGO), and optional Propeller flow
- **systemd + systemd-boot**
- optional **LUKS2 encryption** with **TPM2 auto-unlock** (fallback passphrase always kept)
- profiles:
  - `tty` (minimal)
  - `plasma` (Wayland + PipeWire + Discover/Flatpak)
  - `gamemode` (Steam + Gamescope session at boot, with Plasma “Return to Desktop”)
- device add-ons:
  - `rog-ally` module (installs **hhd** + sensible defaults)

> ⚠️ This is intentionally aggressive and “bleeding edge”. It aims to remain bootable and Steam-capable, but you are opting into an experimental pipeline.

---

## Quick start (from live USB)

```bash
git clone https://github.com/MiyaSHs/virtual-insanity
cd golden-master
bash install.sh
```

The installer will:
1. Validate network + UEFI
2. Ask a few questions (disk, filesystem, encryption, profile, binary-vs-source for big packages)
3. Install stage3 (systemd profile), Portage, base system
4. Install a bootable kernel (fast path: `gentoo-kernel-bin`), systemd-boot, initramfs (dracut)
5. Configure profiles (tty/plasma/gamemode) + optional ROG Ally module
6. Drop a **re-optimize** shortcut in Plasma (if installed)

---

## The “Golden Master” optimization loop

This repo sets up a **process-aware perf sampler** + a **profile accumulator**:

- `gm-perf-profiler` (system service):
  - only records perf when a configured trigger process is running (e.g. `steam`, `gamescope`, `java`, `firefox`, etc.)
  - writes short perf chunks into `/var/lib/gm/perf/chunks/`

- `gm-fdo-accumulate` (timer):
  - converts perf chunks into **LLVM sample profiles** (`.afdo`-style) using `llvm-profgen`
  - merges profiles with `llvm-profdata merge -sample`
  - (optional) generates Propeller profiles if `llvm-propeller` is available

- Portage glue:
  - `/etc/portage/bashrc` detects installed targets and injects:
    - ThinLTO, -O3 (for targets), -march=native
    - `-fprofile-sample-use=` when a profile exists
    - Propeller flags when propeller profiles exist

Targets are configured in:
- `files/scripts/gm-fdo-targets.conf` (package atoms, binaries, triggers)

---

## After install: re-optimize workflow

If Plasma is installed you get a launcher:

- **Golden Master: Re-optimize now** (desktop shortcut)
  - runs accumulation
  - then rebuilds only the installed targets that have profiles

You can also run in a terminal:

```bash
sudo gm-optimize
```

---

## Notes / expectations

- **Profiling tiny libs (like GLFW)** is technically possible *if your workload is actually using the system library*. Minecraft usually ships LWJGL natives; unless you force it to use the system `libglfw.so`, recompiling `media-libs/glfw` will have little impact.
- Kernel AutoFDO/Propeller is possible, but not “turnkey” on Gentoo for every custom source tree. This repo ships a safe bootable path and leaves kernel FDO as an optional advanced step.

---

## Layout

```
golden-master/
  install.sh
  lib/
  modules/
  chroot/
  files/
```

Everything is modular; each module is a bash file with a `run()` function.

