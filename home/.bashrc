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

# ---- Tab completion -------------------------------------------------------
# Omarchy binds TAB to menu-complete with show-all-if-ambiguous on, so a Tab
# with hundreds of candidates dumps every one of them inline and scrolls the
# screen away. Route Tab through fzf instead: fzf already installs itself as
# bash's default completer (complete -D), it was just gated behind the `**`
# suffix. An empty trigger makes it fire on a bare Tab.
export FZF_COMPLETION_TRIGGER=''
bind 'TAB: complete'                  # fzf's completer needs plain complete, not menu-complete

# fzf has no candidate-count threshold of its own, so wrap its default
# completer in one: under the limit, hand back an empty COMPREPLY and let
# `-o default` fall through to readline's own filename completion (which keeps
# trailing slashes, quoting and inline prefix-completion); over it, open fzf.
FZF_TAB_MIN_CANDIDATES=15
__fzf_tab_threshold() {
  local cur expanded count
  cur="${COMP_WORDS[COMP_CWORD]}"

  # `**` stays an explicit "use fzf regardless of count" escape hatch
  if [[ $cur == *'**' ]]; then
    local FZF_COMPLETION_TRIGGER='**'
    __fzf_default_completion "$@"
    return
  fi

  # Never expand a word that could execute something
  if [[ $cur == *'$('* || $cur == *'`'* ]]; then
    COMPREPLY=()
    return 0
  fi

  eval "expanded=$cur" 2> /dev/null || expanded=$cur
  count=$(compgen -f -- "$expanded" 2> /dev/null | command grep -c .)

  if (( count <= ${FZF_TAB_MIN_CANDIDATES:-15} )); then
    COMPREPLY=()
    return 0
  fi
  __fzf_default_completion "$@"
}
complete -D -F __fzf_tab_threshold -o default -o bashdefault
bind 'set show-all-if-ambiguous off'  # let fzf present the list instead of pre-dumping it
bind 'set page-completions on'        # paginate the completers fzf does not wrap (git, systemctl)
bind 'set completion-query-items 100'

# gruvbox-dark palette for fzf. Deliberately no bg: colour -- leaving it unset
# lets kitty's 0.85 translucency show through instead of painting it over.
export FZF_DEFAULT_OPTS="--height=45% --layout=reverse --border=rounded --info=inline
  --color=bg+:#3c3836,spinner:#8ec07c,hl:#83a598,fg:#bdae93,header:#83a598
  --color=info:#fabd2f,pointer:#8ec07c,marker:#8ec07c,fg+:#ebdbb2,prompt:#fabd2f,hl+:#83a598"

# Preview pane for Tab completion. fzf's walker emits absolute paths, so {} is
# a valid path whatever the cwd.
# --select-1 accepts immediately when the prefix is already unambiguous, so an
# unsurprising Tab stays instant instead of opening a picker over one row;
# --exit-0 bails out when nothing matches rather than showing an empty pane.
export FZF_COMPLETION_OPTS='--select-1 --exit-0
  --preview "if [ -d {} ]; then eza -la --icons=auto --color=always {}; else bat -n --color=always --line-range :100 {}; fi 2>/dev/null"
  --preview-window=right,55%,wrap,border-left'
