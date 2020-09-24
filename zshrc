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
alias gclean="git branch --merged | egrep -v master | xargs git branch -d"
alias gl='git log --graph --all --pretty=format:"%Cblue%h%Creset %s%C(yellow)%d%Creset (%Cgreen%an%Creset, %C(cyan)%ar%Creset)"'
alias ggpull="git pull origin \$(git rev-parse --abbrev-ref HEAD)"
alias ggpush="git push origin \$(git rev-parse --abbrev-ref HEAD)"
alias tc="tmux show-buffer | pbcopy"
alias c="clear"
alias l="ls -GFlash"
alias tree="tree -C"
alias ..="cd .."

# Keyboard timeout
export KEYTIMEOUT=1

# Use nvim
export EDITOR=nvim
alias vim="nvim"

export LANG=en_US.UTF-8

# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Manual nvm installation for shell startup speed
export PATH="/Users/$USER/.nvm/versions/node/v12.13.1/bin:$PATH"

# Set npx shell auto fallback
source <(npx --shell-auto-fallback zsh)

# direnv zsh integration
eval "$(direnv hook $SHELL)"

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

# The next line updates PATH for the Google Cloud SDK
if [ -f '/Users/jocke/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/jocke/Downloads/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud
if [ -f '/Users/jocke/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/jocke/Downloads/google-cloud-sdk/completion.zsh.inc'; fi

# Use agr to find replace using ag
function agr { ag -0 -l "$1" | AGR_FROM="$1" AGR_TO="$2" xargs -0 perl -pi -e 's/$ENV{AGR_FROM}/$ENV{AGR_TO}/g'; }

# Setup rbenv
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

# Setup pyenv
eval "$(pyenv init -)"
