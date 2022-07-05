if [ -r ~/.bashrc ]; then
   source ~/.bashrc
fi

complete -C /opt/homebrew/bin/terraform terraform
