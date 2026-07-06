# Prompt with exit code, server role, user, host and working directory.

__server_setup_color() {
    [ -t 1 ] || return 1
    command -v tput >/dev/null 2>&1 || return 1
    tput setaf 1 >/dev/null 2>&1
}

__server_setup_role() {
    if [ -r /etc/server-role ]; then
        tr -cd '[:alnum:]_.:-' < /etc/server-role | head -c 24
    else
        printf "server"
    fi
}

__server_setup_set_prompt() {
    local exit_code="$1"
    local role="$(__server_setup_role)"
    local exit_part=""

    if [ "$exit_code" -ne 0 ]; then
        exit_part="[$exit_code] "
    fi

    if __server_setup_color; then
        PS1="${exit_part}\[\033[01;35m\][$role]\[\033[00m\] \[\033[01;31m\]\u\[\033[01;33m\]@\[\033[01;36m\]\h \[\033[01;33m\]\w \[\033[01;35m\]\\$ \[\033[00m\]"
    else
        PS1="${exit_part}[$role] \u@\h \w \\$ "
    fi

    case "$TERM" in
        xterm*|rxvt*) PS1="\[\e]0;\u@\h: \w\a\]$PS1" ;;
    esac
}

__server_setup_prompt_command() {
    local exit_code="$?"
    history -a
    history -n
    __server_setup_set_prompt "$exit_code"
    return "$exit_code"
}

PROMPT_COMMAND="__server_setup_prompt_command"
