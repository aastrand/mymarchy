# Omarchy environment (OMARCHY_PATH + PATH), needed even for non-interactive shells
[[ -r /usr/share/omarchy/default/bash/env-bootstrap ]] && source /usr/share/omarchy/default/bash/env-bootstrap

# If not running interactively, don't do anything else (leave this above the rc source)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source "$OMARCHY_PATH/default/bash/rc"

# Add your own exports, aliases, and functions here.
#
# Make an alias for invoking commands you use constantly
# alias p='python'
. "$HOME/.cargo/env"

# Give back real GNU ls -- eza's flag grammar breaks habits like `ls -alstr`
# (eza's -s is --sort and demands an argument). eza moves to ll/lla instead.
unalias ls 2>/dev/null
# LS_COLORS: gruvbox-dark via vivid, falling back to the stock dircolors palette
if command -v vivid &>/dev/null; then
  export LS_COLORS="$(vivid generate gruvbox-dark)"
elif [[ -x /usr/bin/dircolors ]]; then
  eval "$(dircolors -b)"
fi
# no --group-directories-first here: it groups dirs separately and so breaks
# `ls -alstr`, where the whole point is that the newest entry is the last line
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias ll='eza -lh --group-directories-first --icons=auto'
alias lla='ll -a'
alias llt='eza -lah -S --icons=auto --sort=modified'  # newest last, the -alstr view
