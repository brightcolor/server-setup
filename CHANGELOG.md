# Changelog

## 2026-07-06

- Renamed the project documentation and defaults from `server-init-setup` to `server-setup`.
- Replaced the monolithic root `.bashrc` with a modular `/root/.bashrc.d` layout.
- Added server-focused Bash helpers for history, prompt, aliases, functions, systemd, APT, ISPConfig and Docker.
- Added `/etc/server-role` support for visible environment context in the shell prompt.
- Reworked `setup.sh` into an idempotent installer with root checks, options and backups.
- Added daily self-update support through `server-setup-update.service` and `server-setup-update.timer`.
- Added a `server-setup` command with `status`, `update` and `uninstall`.
- Added Git attributes to keep server-side shell and systemd files on LF line endings.
- Made system upgrades explicit with `--upgrade-system` instead of running them by default.
- Added `--dry-run`, `--no-packages`, `--no-auto-update`, `--update-only`, `--ref`, `--repo-url` and `--uninstall`.
- Replaced the Python 2 MOTD update checker with a Bash implementation.
- Modernized the system information MOTD script for current Debian/Ubuntu systems.
- Disabled Ubuntu vendor MOTD help/news blocks during setup.
- Disabled Ubuntu minimized-system MOTD notices during setup.
- Guarded ISPConfig MOTD output behind an explicit ISPConfig installation check.
- Fixed ISPConfig version parsing so only `ISPC_APP_VERSION` is printed.
- Added cached current ISPConfig version output below the local version in MOTD.
- Removed insecure `--no-check-certificate` download behavior from the setup flow.
