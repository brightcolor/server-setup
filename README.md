# server-setup

Small Debian/Ubuntu server bootstrap for root shell defaults, MOTD output and daily self-updates.

The project started as a very compact personal setup script and has grown over time. This version keeps that practical spirit, but moves the setup into a cleaner, repeatable layout.

## What It Installs

- Modular root Bash configuration in `/root/.bashrc.d`
- Useful aliases and functions for daily server work
- ISPConfig helpers when `/usr/local/ispconfig` exists
- Optional Docker aliases when Docker is installed
- Dynamic MOTD scripts in `/etc/update-motd.d`
- Daily auto-update timer via systemd
- `server-setup` status/update/uninstall command
- Backups before managed files are replaced

## Install

Run as root:

```bash
curl -fsSL https://raw.githubusercontent.com/brightcolor/server-setup/master/setup.sh -o /tmp/server-setup.sh
bash /tmp/server-setup.sh
```

The installer clones the repository to:

```text
/opt/server-setup
```

It then installs managed files from that local checkout.

## Common Options

```bash
bash setup.sh --dry-run
bash setup.sh --no-packages
bash setup.sh --upgrade-system
bash setup.sh --no-auto-update
bash setup.sh --ref v1.0.0
bash setup.sh --uninstall
```

By default, the installer installs useful packages but does not run a full system upgrade. Use `--upgrade-system` when that is wanted.

## Auto-Update

Auto-update is handled by:

```text
server-setup-update.service
server-setup-update.timer
```

The timer runs daily with a randomized delay and executes:

```bash
/opt/server-setup/setup.sh --update-only --no-packages
```

Useful commands:

```bash
server-setup status
server-setup update
systemctl status server-setup-update.timer
systemctl list-timers server-setup-update.timer
journalctl -u server-setup-update.service
```

## Bash Features

The root Bash setup is loaded from:

```text
/root/.bashrc.d/
```

Files are split by purpose:

```text
00-history.sh
05-completion.sh
10-prompt.sh
20-aliases.sh
30-functions.sh
40-systemd.sh
50-apt.sh
60-ispconfig.sh
70-docker.sh
```

Host-specific changes should go into:

```text
/root/.bashrc.local
```

That file is not managed by this project.

## ISPConfig Helpers

When ISPConfig is detected, these helpers become available:

```bash
ispc
webroot
clients
ispc_version
ispc_services
ispc_logs
siteowner
sitecd
mailq
mailq_count
web_configtest
wpcli
```

Examples:

```bash
ispc_version
ispc_services
cd /var/www/clients/client1/web1/web
wpcli plugin list
sitecd example.com
web_configtest
```

`wpcli` runs WP-CLI as the detected website owner.

## Server Role

Create `/etc/server-role` to show a role in the shell prompt:

```bash
echo prod > /etc/server-role
```

Examples:

```text
[prod] root@web01 /var/www #
[test] root@staging01 /var/www #
```

## Backups

Changed files are backed up before replacement:

```text
/var/backups/server-setup/
```

## Uninstall

```bash
server-setup uninstall
```

This removes managed systemd units, managed Bash files and managed MOTD scripts. Existing backups are kept.

## Repository Rename

This project is intended to live at:

```text
brightcolor/server-setup
```

After renaming the GitHub repository, update any old install snippets that still point to `brightcolor/server-init-setup`.
