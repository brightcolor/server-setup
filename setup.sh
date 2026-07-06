#!/usr/bin/env bash

set -euo pipefail

ORIGINAL_ARGS=("$@")
PROJECT_NAME="server-setup"
REPO_URL="${SERVER_SETUP_REPO_URL:-https://github.com/brightcolor/server-setup.git}"
REF="${SERVER_SETUP_REF:-master}"
INSTALL_DIR="${SERVER_SETUP_INSTALL_DIR:-/opt/server-setup}"
TARGET_HOME="${SERVER_SETUP_HOME:-/root}"
BACKUP_DIR="${SERVER_SETUP_BACKUP_DIR:-/var/backups/server-setup}"

DRY_RUN=0
INSTALL_PACKAGES=1
UPGRADE_SYSTEM=0
AUTO_UPDATE=1
UPDATE_ONLY=0
UNINSTALL=0

usage() {
    cat <<EOF
Usage: $0 [options]

Options:
  --dry-run              Show actions without changing the system
  --no-packages          Skip package installation
  --upgrade-system       Run apt upgrade during setup
  --no-auto-update       Do not install or enable the systemd timer
  --update-only          Pull the repo and reinstall managed files
  --uninstall            Remove managed files and auto-update units
  --ref <ref>            Git branch, tag or commit to use
  --repo-url <url>       Git repository URL
  -h, --help             Show this help
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run) DRY_RUN=1 ;;
        --no-packages) INSTALL_PACKAGES=0 ;;
        --upgrade-system) UPGRADE_SYSTEM=1 ;;
        --no-auto-update) AUTO_UPDATE=0 ;;
        --update-only) UPDATE_ONLY=1; INSTALL_PACKAGES=0 ;;
        --uninstall) UNINSTALL=1 ;;
        --ref) REF="${2:?Missing value for --ref}"; shift ;;
        --repo-url) REPO_URL="${2:?Missing value for --repo-url}"; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
    esac
    shift
done

log() {
    printf '[%s] %s\n' "$PROJECT_NAME" "$*"
}

run() {
    if [ "$DRY_RUN" -eq 1 ]; then
        printf '[dry-run] %s\n' "$*"
    else
        "$@"
    fi
}

require_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "Run this script as root." >&2
        exit 1
    fi
}

ensure_git() {
    if command -v git >/dev/null 2>&1; then
        return
    fi

    if [ "$INSTALL_PACKAGES" -eq 0 ]; then
        echo "git is required. Re-run without --no-packages or install git first." >&2
        exit 1
    fi

    run apt-get update
    run apt-get install -y git ca-certificates
}

sync_repo() {
    ensure_git

    if [ ! -d "$INSTALL_DIR/.git" ]; then
        run mkdir -p "$(dirname "$INSTALL_DIR")"
        run git clone "$REPO_URL" "$INSTALL_DIR"
    else
        run git -C "$INSTALL_DIR" fetch --prune origin
    fi

    run git -C "$INSTALL_DIR" checkout "$REF"

    [ "$DRY_RUN" -eq 0 ] || return 0

    if [ "$(git -C "$INSTALL_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null)" != "HEAD" ]; then
        run git -C "$INSTALL_DIR" pull --ff-only
    fi
}

bootstrap_into_install_dir() {
    local script_path
    script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

    if [ "${SERVER_SETUP_BOOTSTRAPPED:-0}" = "1" ] || [ "$script_path" = "$INSTALL_DIR/setup.sh" ]; then
        return
    fi

    log "Installing repository into $INSTALL_DIR"
    sync_repo

    if [ "$DRY_RUN" -eq 1 ]; then
        log "Dry run stopped before executing $INSTALL_DIR/setup.sh"
        exit 0
    fi

    SERVER_SETUP_BOOTSTRAPPED=1 exec bash "$INSTALL_DIR/setup.sh" "${ORIGINAL_ARGS[@]}"
}

backup_file() {
    local target="$1"
    local source="$2"
    local backup

    [ -e "$target" ] || return 0
    cmp -s "$source" "$target" && return 0

    backup="$BACKUP_DIR$(dirname "$target")/$(basename "$target").$(date +%Y%m%d-%H%M%S)"
    run mkdir -p "$(dirname "$backup")"
    run cp -a "$target" "$backup"
}

install_managed_file() {
    local mode="$1"
    local source="$2"
    local target="$3"

    backup_file "$target" "$source"
    run install -D -m "$mode" "$source" "$target"
}

install_packages() {
    [ "$INSTALL_PACKAGES" -eq 1 ] || return 0
    command -v apt-get >/dev/null 2>&1 || return 0

    log "Installing base packages"
    run apt-get update
    run apt-get install -y \
        aptitude ca-certificates sudo curl wget git bash-completion \
        command-not-found figlet ncdu mc iotop htop iftop nload vnstat \
        mutt nano apt-transport-https tree unzip p7zip-full lsb-release python3

    if [ "$UPGRADE_SYSTEM" -eq 1 ]; then
        log "Upgrading system packages"
        run apt-get upgrade -y
    fi

    if command -v update-command-not-found >/dev/null 2>&1; then
        run update-command-not-found || true
    fi
}

install_shell_files() {
    local file

    log "Installing shell configuration"
    install_managed_file 0755 "$INSTALL_DIR/files/bin/server-setup" /usr/local/sbin/server-setup
    install_managed_file 0644 "$INSTALL_DIR/files/.bashrc" "$TARGET_HOME/.bashrc"
    install_managed_file 0644 "$INSTALL_DIR/files/.bash_aliases" "$TARGET_HOME/.bash_aliases"
    run mkdir -p "$TARGET_HOME/.bashrc.d"

    for file in "$INSTALL_DIR"/files/bashrc.d/*.sh; do
        install_managed_file 0644 "$file" "$TARGET_HOME/.bashrc.d/$(basename "$file")"
    done
}

install_motd_files() {
    local file

    log "Installing MOTD scripts"
    run mkdir -p /etc/update-motd.d

    for file in "$INSTALL_DIR"/files/00-header "$INSTALL_DIR"/files/10-sysinfo "$INSTALL_DIR"/files/20-updates "$INSTALL_DIR"/files/90-footer; do
        install_managed_file 0755 "$file" "/etc/update-motd.d/$(basename "$file")"
    done

    disable_vendor_motd_noise

    if [ -L /etc/motd ]; then
        return
    fi

    if [ -e /etc/motd ]; then
        run mv /etc/motd "/etc/motd.backup.$(date +%Y%m%d-%H%M%S)"
    fi

    run ln -s /var/run/motd /etc/motd
}

disable_vendor_motd_noise() {
    local script

    for script in \
        /etc/update-motd.d/10-help-text \
        /etc/update-motd.d/50-motd-news \
        /etc/update-motd.d/60-unminimize \
        /etc/update-motd.d/80-livepatch \
        /etc/update-motd.d/85-fwupd \
        /etc/update-motd.d/88-esm-announce; do
        [ -e "$script" ] || continue
        run chmod -x "$script"
    done
}

install_auto_update() {
    [ "$AUTO_UPDATE" -eq 1 ] || return 0
    command -v systemctl >/dev/null 2>&1 || return 0

    log "Installing auto-update timer"
    install_managed_file 0644 "$INSTALL_DIR/files/systemd/server-setup-update.service" /etc/systemd/system/server-setup-update.service
    install_managed_file 0644 "$INSTALL_DIR/files/systemd/server-setup-update.timer" /etc/systemd/system/server-setup-update.timer
    run systemctl daemon-reload
    run systemctl enable --now server-setup-update.timer
}

uninstall() {
    log "Removing managed systemd units and shell/MOTD files"
    if command -v systemctl >/dev/null 2>&1; then
        run systemctl disable --now server-setup-update.timer || true
    fi

    run rm -f /etc/systemd/system/server-setup-update.service
    run rm -f /etc/systemd/system/server-setup-update.timer
    run rm -f /usr/local/sbin/server-setup
    run rm -f "$TARGET_HOME/.bashrc" "$TARGET_HOME/.bash_aliases"
    run rm -f "$TARGET_HOME/.bashrc.d/00-history.sh"
    run rm -f "$TARGET_HOME/.bashrc.d/05-completion.sh"
    run rm -f "$TARGET_HOME/.bashrc.d/10-prompt.sh"
    run rm -f "$TARGET_HOME/.bashrc.d/20-aliases.sh"
    run rm -f "$TARGET_HOME/.bashrc.d/30-functions.sh"
    run rm -f "$TARGET_HOME/.bashrc.d/40-systemd.sh"
    run rm -f "$TARGET_HOME/.bashrc.d/50-apt.sh"
    run rm -f "$TARGET_HOME/.bashrc.d/60-ispconfig.sh"
    run rm -f "$TARGET_HOME/.bashrc.d/70-docker.sh"
    run rm -f /etc/update-motd.d/00-header /etc/update-motd.d/10-sysinfo /etc/update-motd.d/20-updates /etc/update-motd.d/90-footer

    if command -v systemctl >/dev/null 2>&1; then
        run systemctl daemon-reload
    fi
}

main() {
    require_root

    if [ "$UNINSTALL" -eq 1 ]; then
        uninstall
        return
    fi

    bootstrap_into_install_dir
    sync_repo
    install_packages
    install_shell_files
    install_motd_files
    install_auto_update

    log "Done"
}

main "$@"
