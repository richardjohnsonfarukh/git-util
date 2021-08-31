# Git Utils!

## Intro
This project has the following goals:

1. Circumvent copy and pasting file names that you want to add to the staging area
2. Keep a convention for commit messages
3. Automatically set your upstream to have the same name as your current branch if your push fails

## Prerequisites

1. You need to have ruby installed (preferably version 2.7.2 and up)
2. You should have a **.bash_profile** or a **.zshrc** file in your home directory for aliases and environmental variables
## Installation
1. Clone the git repository

   `$ git clone https://github.com/richardjohnsonfarukh/git-util.git`

2. Run setup script 

   `$ ./setup.sh`
   
   The script will: 
   - Change your default ruby home path, which will allow you to install gems in a non restricted folder
   - Add an alias for the command **acp** to be used from any directory
   - Create an empty **co-authors.yml** file for you to populate
   - Install bundler and all the required dependencies for you to be able to run the script

3. You are ready to use the `acp` command!

## Usage

You can use the command as follows:

`$ acp [options]`

| options           | function                                            |
| ----------------- | --------------------------------------------------- |
| `-a`, `--all`     | adds all git files before executing                 |
| `-d`, `--debug`   | doesn't execute git commands - used for development |
| `-v`, `--verbose` | prints all executed git commands                    |
| `-h`, `--help`    | prints help menu                                    |