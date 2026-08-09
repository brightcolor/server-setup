# Small interactive helpers.

mkcd() {
    [ $# -eq 1 ] || { echo "Usage: mkcd <directory>"; return 2; }
    mkdir -p "$1" && cd "$1"
}

extract() {
    [ $# -eq 1 ] || { echo "Usage: extract <archive>"; return 2; }
    [ -f "$1" ] || { echo "Not a file: $1"; return 1; }

    case "$1" in
        *.tar.bz2) tar xjf "$1" ;;
        *.tar.gz|*.tgz) tar xzf "$1" ;;
        *.tar.xz) tar xJf "$1" ;;
        *.tar) tar xf "$1" ;;
        *.bz2) bunzip2 "$1" ;;
        *.gz) gunzip "$1" ;;
        *.zip) unzip "$1" ;;
        *.7z) 7z x "$1" ;;
        *) echo "Cannot extract: $1"; return 1 ;;
    esac
}

pubip() {
    curl -fsS4 https://ifconfig.me || curl -fsS4 https://icanhazip.com
    echo
}

serve() {
    local port="${1:-8000}"
    python3 -m http.server "$port"
}

email() {
    [ $# -eq 3 ] || { echo "Usage: email <to> <subject> <body>"; return 2; }
    echo "$3" | mutt -s "$2" "$1"
}

transfer() {
    [ $# -eq 1 ] || { echo "Usage: transfer <file>"; return 2; }
    [ -f "$1" ] || { echo "Not a file: $1"; return 1; }
    curl --progress-bar --upload-file "$1" "https://transfer.sh/$(basename "$1")"
    echo
}

wpdebug() {
    local val
    case "$1" in
        on)  val=true ;;
        off) val=false ;;
        *) echo "Usage: wpdebug on|off" >&2; return 1 ;;
    esac
    wp config set WP_DEBUG "$val" --raw
    wp config set WP_DEBUG_LOG "$val" --raw
    wp config set WP_DEBUG_DISPLAY "$val" --raw
}
