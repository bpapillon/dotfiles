#!/bin/bash

read -p "Install & setup 1Password and then press enter to continue..."

echo "Checking git and xcode installation..."
git --version # Will prompt for xcode tools setup if needed

read -p "Set up a new SSH key, add it to GitHub, then press enter to continue..."

echo "Setting bash as default shell..."
chsh -s /bin/bash

echo "Installing dotfiles..."
echo "TODO: set up dotfiles (https://github.com/bpapillon/dotfiles)"
exit 1

echo "Activating bash profile..."
source ~/.bash_profile

# TODO: SSL setup

echo "Installing Homebrew..." # TODO check if homebrew already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

echo "Installing golang via Homebrew..."
brew update && brew install golang
echo "Installing npm via Homebrew..."
brew install npm
echo "Installing pyenv via Homebrew..."
brew install pyenv
echo "Installing rbenv via Homebrew..."
brew install rbenv

echo "Installing nvm via curl-bash..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash

echo "Setting up notes and projects directories..."
mkdir ~/projects
git clone git@github.com:bpapillon/notes.git ~/notes/

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
* chrome://settings/content/notifications - disallow sites from asking for permission to send notifications
* Enable hot corner to lock screen
EOF

