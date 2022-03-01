#!/bin/bash

BASH_PROFILE=~/.bash_profile
BASHRC=~/.bashrc
ZSHRC=~/.zshrc
DIRNAME="$( dirname "${BASH_SOURCE[0]}" &> /dev/null && pwd )"

function add_alias {
   printf "\nalias acp=$DIRNAME/src/script.rb\n" >> $1
   echo "export GEM_HOME=\"$HOME/.gem\"" >> $1
   source $1
   gem install bundler && bundle
}

function app_file_setup {
   cp $DIRNAME/src/config/config_template.yml $DIRNAME/src/config/config.yml
   mkdir $DIRNAME/.cache
   echo  "---" > "$DIRNAME/src/config/co-authors.yml"
}

app_file_setup

if [[ -f $ZSHRC ]]; then 
   add_alias $ZSHRC;
elif [[ -f $BASH_PROFILE ]]; then
   add_alias $BASH_PROFILE;
elif [[ -f $BASHRC ]]; then
   add_alias $BASHRC;
else 
   echo "No candidates for a script found - exiting";
   exit 1
fi

echo "Installation complete! Use 'acp -h' for help with the command"
