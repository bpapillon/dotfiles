### Prompt

autoload -Uz vcs_info
precmd() { vcs_info }

zstyle ':vcs_info:git:*' formats '(%b)'
zstyle ':vcs_info:*' enable git

setopt PROMPT_SUBST
PROMPT='^%F{magenta}%1~%f %F{cyan}${vcs_info_msg_0_}%f$ '

### PATH & other important stuff

export EDITOR=nvim
export PATH=/opt/local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/sbin:/usr/local/include/:$HOME/bin:$HOME/.local/bin

### Misc aliases

alias config="/usr/bin/git --git-dir=/Users/bpapillon/.cfg/ --work-tree=/Users/bpapillon"
alias dc="docker-compose"
alias dcu="docker-compose up -d"
alias grep="grep --color=never"
alias ll="ls -al"
alias ls="ls -G"
alias v="nvim"
alias vi="nvim"
alias vim="nvim"
alias vun="nvim"

### History

HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000000
SAVEHIST=10000000
HISTORY_IGNORE="(ls|cd|pwd|exit|cd)*"

setopt EXTENDED_HISTORY      # Write the history file in the ':start:elapsed;command' format.
setopt INC_APPEND_HISTORY    # Write to the history file immediately, not when the shell exits.
setopt SHARE_HISTORY         # Share history between all sessions.
setopt HIST_IGNORE_DUPS      # Do not record an event that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS  # Delete an old recorded event if a new event is a duplicate.
setopt HIST_IGNORE_SPACE     # Do not record an event starting with a space.
setopt HIST_SAVE_NO_DUPS     # Do not write a duplicate event to the history file.
setopt HIST_VERIFY           # Do not execute immediately upon history expansion.
setopt APPEND_HISTORY        # append to history file (Default)
setopt HIST_NO_STORE         # Don't store history commands
setopt HIST_REDUCE_BLANKS    # Remove superfluous blanks from each command line being added to the history.

### Git

alias g="git"
alias gb="g b"
alias gd="g d"
alias gp="g p"
alias gs="g s"

### Language support and package managers

# Go
export GOPATH="$HOME/go"
export PATH=$PATH:/go/bin:$GOPATH/bin

# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# NVM
if [ -d $HOME/.nvm ]; then
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Bun
BUN_INSTALL="$HOME/.bun"
PATH="$BUN_INSTALL/bin:$PATH"
[ -s "/Users/bpapillon/.bun/_bun" ] && source "/Users/bpapillon/.bun/_bun"

# Yarn
export PATH=$PATH:$HOME/.yarn/bin/

# Dotnet
export DOTNET_ROOT=/usr/local/share/dotnet
export PATH=$PATH:$DOTNET_ROOT

### GitHub

function gh_url {
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
function ghc {
  gh_url $1 | pbcopy
}
function gho {
  gh_url $1 | xargs open
}

### Schematic

SCHEMATIC_PROJECT_DIR="$HOME/projects/schematic/"
SCHEMATIC_API_TEST_CONFIG="$HOME/projects/schematic/api/test.env"
export PATH=$PATH:$HOME/projects/schematic/developers/bin/

### Secrets

if [ -f ~/.zsh_secrets ]; then
    source ~/.zsh_secrets
fi


### Helper

function kill_process_on_port() {
  if [ $# -eq 0 ]; then
    echo "Usage: kill_process_on_port <port1> [port2] [port3] ..."
    return 1
  fi

  for PORT in "$@"
  do
    if ! [[ "$PORT" =~ ^[0-9]+$ ]]; then
      echo "Invalid port number: $PORT"
      continue
    fi

    PID=$(lsof -ti:$PORT)
    if [ -z "$PID" ]; then
      echo "No process running on port $PORT"
    else
      kill -9 $PID
      echo "Killed process $PID running on port $PORT"
    fi
  done
}
alias killport="kill_process_on_port"

# Java
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# Claude Code
alias claude="/Users/bpapillon/.claude/local/claude"
