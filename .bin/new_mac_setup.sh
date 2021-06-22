#!/bin/bash

echo "Setting bash as default shell..."
chsh -s /bin/bash
source ~/.bashrc

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
echo "TODO: set up dotfiles (https://github.com/bpapillon/dotfiles)"
exit 1

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
echo "Installing hugo via Homebrew..."
brew install hugo
echo "Installing jq via Homebrew..."
brew install jq

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
* Enable hot corner to lock screen
* Set Do Not Disturb to "Always On"
* chrome://settings/content/notifications - disallow sites from asking for permission to send notifications
EOF

