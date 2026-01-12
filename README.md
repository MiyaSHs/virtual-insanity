# Golden Master Gentoo (extreme optimization scaffolding)

This repo installs a Gentoo system from a live USB with:
- systemd + systemd-boot
- optional LUKS2 root encryption (tries TPM auto-unlock if available)
- profiles: tty, plasma, gamemode (Steam+Gamescope)
- device module: ROG Ally (hhd, handheld tweaks)
- perf → AutoFDO/Propeller framework (process-aware capture, profile conversion, Portage env injection)
- a "Re-optimize" desktop launcher (Plasma only)

## Run
From Gentoo live USB (root, after connecting to wifi):
```bash
git clone https://github.com/YOU/golden-master.git
cd golden-master
bash install.sh
