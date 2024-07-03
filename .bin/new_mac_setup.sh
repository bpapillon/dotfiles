#!/bin/bash

check_bin_install() {
  COMMAND=${1}
  echo "Checking for ${COMMAND} binary...\n"
  if [ -x "$(which ${COMMAND})" ]; then
    echo "INSTALLED\n"
    return 0
  else
    echo "NOT FOUND\n"
    return 1
  fi
}

install_with_brew() {
  BREW_PACKAGE=${1}
  echo "Installing ${BREW_PACKAGE} with brew...\n"
  brew install ${BREW_PACKAGE}
  check_return_code $?
}

install_with_curl() {
  CURL_PACKAGE=${1}
  CURL_URL=${2}
  echo "Installing ${CURL_PACKAGE} with curl from ${CURL_URL}...\n"
  /bin/bash -c "$(curl -fsSL ${CURL_URL})"
  check_return_code $?
}

install_with_npm() {
  echo "Installing ${NPM_PACKAGE} with npm...\n"
  npm install --global $NPM_PACKAGE
}

install_nvm() {
  INSTALL_URL="https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh"
  echo "Installing nvm with curl from ${CURL_URL}...\n"
  curl -o- $CURL_URL | bash
  nvm install 20
}

install_rust() {
  CURL_URL="https://sh.rustup.rs"
  echo "Installing nvm with curl from ${CURL_URL}...\n"
  curl –proto '=https' –tlsv1.2 -sSf $CURL_URL | sh
}

echo "Checking git and xcode installation..."
git --version # Will prompt for xcode tools setup if needed

if [[ ! -d ~/.ssh/ ]]; then
  echo "Creating ~/.ssh/ directory..."
  mkdir -p ~/.ssh
fi

if [ -f "~/.ssh/id_rsa.pub" ]; then
  echo "Using existing public key ~/.ssh/id_rsa.pub..."
else
  echo "Generating a new SSH key..."
  ssh-keygen -f ~/.ssh/id_rsa -t rsa -b 2048 -C "benpapillon@gmail.com"
fi

cat ~/.ssh/id_rsa.pub | pbcopy
read -p "Public key has been copied to your clipboard. Add it to Github (https://github.com/settings/ssh/new), then press enter to continue..."

echo "Installing dotfiles..."
curl -Ls https://raw.githubusercontent.com/bpapillon/dotfiles/master/.bin/install.sh | /bin/bash

check_bin_install "brew" || install_with_curl "brew" "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
brew update

# Go
check_bin_install "go" || install_with_brew "go"
check_bin_install "golangci-lint" || install_with_brew "golangci-lint"
check_bin_install "hugo" || install_with_brew "hugo"

# JavaScript
check_bin_install "nvm" || install_nvm
check_bin_install "yarn" || install_with_npm "yarn"
check_bin_install "prettier" || install_with_npm "prettier"
check_bin_install "typescript-language-server" || install_with_npm "typescript-language-server"
check_bin_install "bun" || install_with_curl "bun" "https://bun.sh/install"

# Postgres
check_bin_install "psql" || install_with_brew "postgresql"
check_bin_install "pgcli" || brew tap dbcli/tap && brew install pgcli

# PHP
check_bin_install "php" || install_with_brew "php"

# misc
check_bin_install "nvim" || install_with_brew "nvim"
check_bin_install "fd" || install_with_brew "fd"
check_bin_install "jq" || install_with_brew "jq"
check_bin_install "ripgrep" || install_with_brew "ripgrep"
check_bin_install "ag" || install_with_brew "the_silver_searcher"
check_bin_install "op" || brew install --cask 1password/tap/1password-cli
check_bin_install "figlet" || install_with_brew "figlet"

# Schematic
check_bin_install "mintlify" || install_with_npm "mintlify"
check_bin_install "openapi_generator" || install_with_brew "openapi_generator"
check_bin_install "pulumi" || install_with_brew "pulumi"
