# History settings for interactive server shells.

HISTCONTROL=ignoreboth
HISTFILESIZE=99999999
HISTSIZE=99999999
HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S "

shopt -s histappend
shopt -s checkwinsize

export HISTCONTROL HISTFILESIZE HISTSIZE HISTTIMEFORMAT
