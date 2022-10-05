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
  CURL_URL="https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh"
  echo "Installing nvm with curl from ${CURL_URL}...\n"
  curl -o- $CURL_URL | bash
}

install_rust() {
  CURL_URL="https://sh.rustup.rs"
  echo "Installing nvm with curl from ${CURL_URL}...\n"
  curl –proto '=https' –tlsv1.2 -sSf $CURL_URL | sh
}

if [ "$SHELL" != "/bin/bash" ]; then
  echo "Setting bash as default shell..."
  chsh -s /bin/bash
  source ~/.bashrc
fi

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

check_bin_install "go" || install_with_brew "go"
check_bin_install "nvm" || install_nvm
check_bin_install "rust" || install_rust

check_bin_install "awslogs" || install_with_brew "awslogs"
check_bin_install "fd" || install_with_brew "fd"
check_bin_install "hugo" || install_with_brew "hugo"
check_bin_install "jq" || install_with_brew "jq"
check_bin_install "nvim" || install_with_brew "nvim"
check_bin_install "psql" || install_with_brew "postgresql"
check_bin_install "pyenv" || install_with_brew "pyenv"
check_bin_install "rbenv" || install_with_brew "rbenv"
check_bin_install "ripgrep" || install_with_brew "ripgrep"
check_bin_install "yarn" || install_with_npm "yarn"

echo "Setting up notes and projects directories..."
if [[ ! -f "~/projects" ]]
then
  mkdir ~/projects
fi
if [[ ! -f "~/notes" ]]
then
  git clone git@github.com:bpapillon/notes.git ~/notes/
fi

cat << EOF
Download and install the following apps:
* [Alfred](https://www.alfredapp.com/) - remember to configure the prompt keystroke after installing
* [Brave browser](https://brave.com/)
* [Chrome browser](https://www.google.com/chrome/)
* [Docker for Mac](https://docs.docker.com/docker-for-mac/install/)
* [Rectangle window manager](https://rectangleapp.com/) - remember to configure the keystrokes after installing
* [Sonos S2 controller](https://support.sonos.com/s/downloads?language=en_US)
* [Spotify](https://www.spotify.com/us/download/mac/)
* [Zoom](https://zoom.us/download#client_4meeting)

Set up your Apple ID, and install the following apps via the App Store:
* Pocket
* Twitter

And then some settings to configure:
* Enable hot corner to lock screen
* Set Do Not Disturb to "Always On"
* chrome://settings/content/notifications - disallow sites from asking for permission to send notifications
EOF

