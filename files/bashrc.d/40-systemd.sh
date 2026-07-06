# systemd and log shortcuts.

alias sctl='systemctl'
alias jctl='journalctl'
alias failed='systemctl --failed'
alias bootlog='journalctl -b'

svc() {
    [ $# -ge 1 ] || { echo "Usage: svc <unit>"; return 2; }
    systemctl status "$@" --no-pager
}

logs() {
    [ $# -ge 1 ] || { echo "Usage: logs <unit>"; return 2; }
    journalctl -u "$1" -f --since "1 hour ago"
}

restart() {
    [ $# -ge 1 ] || { echo "Usage: restart <unit>"; return 2; }
    systemctl restart "$@"
}

enable() {
    [ $# -ge 1 ] || { echo "Usage: enable <unit>"; return 2; }
    systemctl enable --now "$@"
}
