# Common aliases for Debian/Ubuntu server administration.

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias c='clear'
alias h='history'
alias reload='source ~/.bashrc'

alias ls='ls -hF --color=auto'
alias ll='ls -lahF --color=auto'
alias lsl='ls -lhF --color=auto'
alias grep='grep --color=auto'
alias df='df -h'
alias du='du -h'
alias free='free -h'

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias chmod='chmod --preserve-root'
alias chown='chown --preserve-root'
alias chgrp='chgrp --preserve-root'

alias path='printf "%s\n" "$PATH" | tr ":" "\n"'
alias ports='ss -tulpn'
alias listeners='ss -ltnp'
alias topmem='ps aux --sort=-%mem | head -15'
alias topcpu='ps aux --sort=-%cpu | head -15'

alias gs='git status --short'
alias gl='git log --oneline --graph --decorate -20'
alias gd='git diff'
alias gp='git pull --ff-only'

alias mkdir='mkdir -p'
alias nano='nano -w'

mcv() {
    mc "/var/www/${1:-}"
}
alias wp='f=./index.php; [ -f "$f" ] || f=.; sudo -u "$(stat -c %U "$f" 2>/dev/null || stat -f %Su "$f")" /usr/local/bin/wp'
