# Load the pure prompt
autoload -Uz promptinit; promptinit
prompt pure

# Init the completion system
autoload -Uz compinit; compinit

# Make completion incasesensitive
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Make sure the completion menu shows
zstyle ':completion:*' menu select

# Make shift tab traverse completion menu in reverse order
zmodload zsh/complist
bindkey -M menuselect '^[[Z' reverse-menu-complete

# Enable vim mode
bindkey -v

# Some aliases
alias gs="git status"
alias gc="git commit --verbose"
alias ga="git add"
alias gb="git branch"
alias gd="git diff"
alias gco="git checkout"
alias grm="git rm"
alias gr="git rebase"
alias gst="git stash"
alias gstp="git stash pop"
alias grc="git rebase --continue"
alias gra="git rebase --abort"
alias gpfwl="git push --force-with-lease"
alias gclean="git branch --merged | egrep -v master | egrep -v main | xargs git branch -d"
alias gl='git log --graph --all --pretty=format:"%Cblue%h%Creset %s%C(yellow)%d%Creset (%Cgreen%an%Creset, %C(cyan)%ar%Creset)"'
alias ggpull="git pull origin \$(git rev-parse --abbrev-ref HEAD)"
alias ggpush="git push origin \$(git rev-parse --abbrev-ref HEAD)"
alias tc="tmux show-buffer | pbcopy"
alias c="clear"
alias l="ls -GFlash"
alias tree="tree -C"
alias ..="cd .."

function gri() {
  git rebase --interactive --autostash --autosquash "$1"~1
}

# Keyboard timeout
export KEYTIMEOUT=1

# Use nvim
export EDITOR=nvim
alias vim="nvim"

export LANG=en_US.UTF-8

# fzf zsh integration
export FZF_DEFAULT_COMMAND='ag -g ""'
export FZF_CTRL_R_OPTS='--height 12'
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Configure history
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt share_history
setopt hist_ignore_dups
setopt hist_save_no_dups
setopt hist_find_no_dups
setopt hist_ignore_all_dups

# Use agr to find replace using ag
function agr { ag -0 -l "$1" | AGR_FROM="$1" AGR_TO="$2" xargs -0 perl -pi -e 's/$ENV{AGR_FROM}/$ENV{AGR_TO}/g'; }

# Setup rbenv
# export PATH="$HOME/.rbenv/bin:$PATH"
# eval "$(rbenv init -)"

# Setup pyenv
# eval "$(pyenv init -)"

# Setup fnm
eval "$(fnm env)"

# Setup Cargo
export PATH="/Users/$USER/.cargo/bin:$PATH"

# Copy xterm-kitty over when using ssh
alias ssh="kitty +kitten ssh"

# Add our own bin to path"
export PATH="$HOME/.bin:$PATH"
