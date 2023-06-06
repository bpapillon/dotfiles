### PS1

PS1='^\e[0;35m\W\e[m\e[0;36m$(parse_git_branch)\e[m\$ '
parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

### PATH & other important stuff

export BASH_SILENCE_DEPRECATION_WARNING=1 # Silence warning to change to zsh
export EDITOR=vim
export GOPATH="$HOME/go"
export PATH=/Applications/Postgres.app/Contents/Versions/latest/bin:/opt/local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/sbin:/usr/local/include/:/usr/local/go/bin:$GOPATH/bin:/usr/local/opt/libpq/bin:/usr/local/mysql/bin:/usr/local/mysql/support-files

### Misc aliases

alias bx='bundle exec'
alias config='/usr/bin/git --git-dir=/Users/bpapillon/.cfg/ --work-tree=/Users/bpapillon'
alias dc='docker-compose'
alias grep='grep --color=always'
alias h='history'
alias ll='ls -al'
alias ls='ls -G'
alias moon='curl -4 http://wttr.in/Moon'
alias rmpyc='find . -name "*.pyc" -delete'
alias ssh_forward='eval $(ssh-agent) && ssh-add ~/.ssh/id_rsa'
alias v='vim'
alias vi="nvim"
alias vim="nvim"
alias vun='vim'
alias weather='curl -4 http://wttr.in/Atlanta'

### History

export HISTCONTROL=ignoredups:erasedups
export HISTSIZE=100000
export HISTFILESIZE=100000
shopt -s histappend
export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"

### Git

alias g='git'

# Common typos
alias gd='g d'
alias gs='g s'
alias gp='g p'
alias hoy='git'

# Git autocompletion
if [ -f ~/.git-completion.bash ]; then
  . ~/.git-completion.bash
fi

### Package and version managers

# homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# nvm
if [ -d $HOME/.nvm ]; then
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
fi

# pyenv
if [ -d $HOME/.pyenv ]; then
  export PYENV_ROOT="$HOME/.pyenv"
  command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init -)"
fi

# rbenv
if [ -d $HOME/.rbenv ]; then
  eval "$(~/.rbenv/bin/rbenv init - bash)"
fi

# haskell/ghcup
[ -f "/Users/bpapillon/.ghcup/env" ] && source "/Users/bpapillon/.ghcup/env" # ghcup-env

# rust/cargo
. "$HOME/.cargo/env"

# bun
BUN_INSTALL="/Users/bpapillon/.bun"
PATH="$BUN_INSTALL/bin:$PATH"

### Note-taking

# Notes
note() {
  vim ~/notes/$(date +%Y%m%d)-$1.txt
}
0note() {
  vim ~/notes/00-$1.txt
}
pnote() {
  vim ~/notes/*-$1.txt
}

# Scratch
scratch() {
  vim ~/projects/scratch/scratch-$(date +%Y%m%d).txt
}

### GitHub

function gl {
  remote_url=$(git remote get-url origin)
  if [[ $remote_url != *"github.com"* ]]; then
    echo "Not a GitHub remote"
    return 1
  fi

  web_url="${remote_url/git@github.com:/https://github.com/}"
  web_url="${web_url%.git}"
  revision=$(git rev-parse HEAD)
  cur_path=$(git rev-parse --show-prefix)
  if [[ -z $1 ]]; then
    echo $web_url
  else
    echo "$web_url/blob/$revision/$cur_path$1"
  fi
}
function glc {
  gl $1 | pbcopy
}
function glo {
  gl $1 | xargs open
}
