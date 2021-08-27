# Git Utils!

## Intro
This project has three main goals

1. Circumvent copy and pasting file names that you want to add to the staging area
2. Keep a convention
## Installation
1. Clone the git repository

   `$ git clone https://github.com/richardjohnsonfarukh/git-util.git`

2. Update gem home directory to be able to install gems without **sudo**

   `$ export GEM_HOME="$HOME/.gem"`

3. Install bundler for adding Ruby dependencies

   `$ gem install bundler && bundle`

4. Add the alias to your profile file using the script from the project
   
   `$ ./create_alias.sh` 

5. You are ready to use the `acp` command!

## Usage

You can use the command as follows

`$ acp [options]`

| options           | function                                            |
| ----------------- | --------------------------------------------------- |
| `-a`, `--all`     | adds all git files before executing                 |
| `-d`, `--debug`   | doesn't execute git commands - used for development |
| `-v`, `--verbose` | prints all executed git commands                    |
| `-h`, `--help`    | prints help menu                                    |