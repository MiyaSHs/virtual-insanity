# golden-master (Gentoo extreme optimization scaffold)

This is a modular Gentoo installer intended to be run from the Gentoo live USB (UEFI) and produce:
- systemd + systemd-boot
- optional full-disk encryption (LUKS2 root)
- profiles: **tty**, **plasma**, **gamemode** (Steam+Gamescope + Plasma fallback)
- optional Flatpak enablement (and optional GUI store)
- a **process-aware perf profiler** that writes chunks to disk only while “interesting” apps are running
- a **profile accumulator** that converts perf chunks into sample profiles (AutoFDO) + Propeller files
- Portage integration that injects flags for installed targets and a one-shot **gm-optimize** rebuild helper

## Quick start (live USB)
```bash
# inside the live environment, as root
git clone https://github.com/YOU/golden-master.git
cd golden-master
bash install.sh
```

## Filesystem notes
- The installer can format root as btrfs/ext4/xfs/bcachefs (bcachefs is experimental).
- For btrfs, you can later enable compression/snapshots; the scaffold keeps the initial mount simple.

## Perf/FDO notes
- Profiling is **process-aware** (does nothing unless configured processes are running).
- Profiles are generated only for targets that are actually installed (mesa/gamescope/kernel by default).
- Expand `/etc/gm-fdo-targets.conf` and `gm-portage-env-apply` mapping to cover more packages.

## Rebuild helper
- `gm-optimize` applies env mappings and rebuilds installed targets.
- In Plasma, you can add the `.desktop` launcher from `files/systemd/user/gm-optimize.desktop`.

## WARNING
This is a scaffold for an extreme-optimization system. Review before running. It will wipe the selected disk.
