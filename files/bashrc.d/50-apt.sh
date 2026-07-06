# APT helpers for Debian/Ubuntu systems.

alias aptup='apt update && apt list --upgradable'
alias aptug='apt update && apt upgrade'
alias aptfull='apt update && apt full-upgrade'
alias aptfix='apt --fix-broken install'
alias aptclean='apt autoremove --purge && apt autoclean'
alias aptsearch='apt-cache search'
alias aptinstalled='apt list --installed'

aptwhy() {
    [ $# -eq 1 ] || { echo "Usage: aptwhy <package>"; return 2; }
    apt-cache rdepends --installed "$1"
}
