# PS1
PS1='^\e[0;35m\W\e[m\e[0;36m$(parse_git_branch)\e[m\$ '
parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

# PATH & misc exports
export BASH_SILENCE_DEPRECATION_WARNING=1 # Silence warning to change to zsh
export EDITOR=vim
export GOPATH="$HOME/go"
export PATH=/Applications/Postgres.app/Contents/Versions/10/bin:/opt/local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/sbin:~/Library/Python/2.7/bin:~/Library/Python/3.7/bin/:/usr/local/include/:/usr/local/go/bin:$GOPATH/bin:/usr/local/opt/libpq/bin

# Aliases
alias bx='bundle exec'
alias chrome='open -a Google\ Chrome'
alias config='/usr/bin/git --git-dir=/Users/bpapillon/.cfg/ --work-tree=/Users/bpapillon'
alias dc='docker-compose'
alias drawio='/Applications/draw.io.app/Contents/MacOS/draw.io'
alias g='git'
alias gitpylint='git status --porcelain | sed s/^...// | xargs pylint'
alias grep='grep --color=always'
alias h='history'
alias hg='history | grep'
alias ll='ls -al'
alias ls='ls -G'
alias moon='curl -4 http://wttr.in/Moon'
alias rmpyc='find . -name "*.pyc" -delete'
alias ssh_forward='eval $(ssh-agent) && ssh-add ~/.ssh/id_rsa'
alias v='vim'
alias weather='curl -4 http://wttr.in/Atlanta'
alias branch_clean="git branch -vv | grep ': gone]' | grep -v '\*' | awk '{print \$1}' | xargs -r git branch -D"

# History
export HISTCONTROL=ignoredups:erasedups
export HISTSIZE=100000
export HISTFILESIZE=100000
shopt -s histappend
export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"

# git autocompletion
if [ -f ~/.git-completion.bash ]; then
  . ~/.git-completion.bash
fi

# print only column x of output
# stolen from https://bitbucket.org/durdn/cfg/src/master/.bashrc
function col {
  awk -v col=$1 '{print $col}'
}

# global search and replace OSX
# stolen from https://bitbucket.org/durdn/cfg/src/master/.bashrc
function sr {
    find . -type f -exec sed -i '' s/$1/$2/g {} +
}

# nvm
if [ -d $HOME/.nvm ]; then
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
fi

# pyenv
if [ -d $HOME/.pyenv ]; then
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init --path)"
fi

# rbenv
if [ -d $HOME/.rbenv ]; then
  eval "$(rbenv init -)"
fi

# haskell/ghcup
[ -f "/Users/bpapillon/.ghcup/env" ] && source "/Users/bpapillon/.ghcup/env" # ghcup-env

# homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

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

# Relay Payments
export DEV_ENV_PATH=$HOME/projects/dev-env
export PATH=$PATH:$DEV_ENV_PATH/bin
export DOCKER_PATH=$DEV_ENV_PATH/docker/relay

function gl {
  REMOTE_URL=$(git remote get-url origin)
  GITLAB_BASE_URL=$(echo $REMOTE_URL | sed 's/^ssh\:\/\/git\@/https\:\/\//; s/\.git$//; s/\:6767//')
  BRANCH_NAME=$(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')
  CURRENT_PATH=$(git rev-parse --show-prefix)
  if [[ -z $1 ]]; then
    echo $GITLAB_BASE_URL
  else
    echo "$GITLAB_BASE_URL/-/blob/$BRANCH_NAME/$CURRENT_PATH$1"
  fi
}
function glc {
  gl $1 | pbcopy
}
function glo {
  gl $1 | xargs open
}
