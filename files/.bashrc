# ~/.bashrc managed by server-setup.
# Put host-specific changes in ~/.bashrc.local.

case $- in
    *i*) ;;
      *) return ;;
esac

export SERVER_SETUP_DIR="${SERVER_SETUP_DIR:-$HOME/.bashrc.d}"

if [ -d "$SERVER_SETUP_DIR" ]; then
    for file in "$SERVER_SETUP_DIR"/*.sh; do
        [ -r "$file" ] && . "$file"
    done
    unset file
fi

if [ -f "$HOME/.bash_aliases" ]; then
    . "$HOME/.bash_aliases"
fi

if [ -f "$HOME/.bashrc.local" ]; then
    . "$HOME/.bashrc.local"
fi
