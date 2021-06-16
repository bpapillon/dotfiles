# PS1
PS1='^\e[0;35m\W\e[m\e[0;36m$(parse_git_branch)\e[m\$ '
parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

# PATH & misc exports
export BASH_SILENCE_DEPRECATION_WARNING=1 # Silence warning to change to zsh
export EDITOR=vim
export PATH=/Applications/Postgres.app/Contents/Versions/10/bin:/opt/local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/sbin:~/Library/Python/2.7/bin:~/Library/Python/3.7/bin/:/usr/local/include/:/usr/local/go/bin:/Users/bpapillon/go/bin

# Aliases
alias bx='bundle exec'
alias config='/usr/bin/git --git-dir=/Users/bpapillon/.cfg/ --work-tree=/Users/bpapillon'
alias dc='docker-compose'
alias gitpylint='git status --porcelain | sed s/^...// | xargs pylint'
alias ll='ls -al'
alias rmpyc='find . -name "*.pyc" -delete'
alias ssh_forward='eval $(ssh-agent) && ssh-add ~/.ssh/id_rsa'

# History
export HISTCONTROL=ignoreboth
shopt -s histappend

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

