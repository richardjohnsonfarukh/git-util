# Git Utils!

## Intro
This project has the following goals:

1. Circumvent copy and pasting file names that you want to add to the staging area
2. Keep a convention for commit messages
3. Easily add co-authors you have previously worked with
4. Automatically push and set your upstream to have the same name as your current branch if your push fails

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

You can use the command the following way:

- `$ acp [options]`

| options           | function                                            |
| ----------------- | --------------------------------------------------- |
| `-a`, `--all`     | adds all git files before executing                 |
| `-d`, `--debug`   | doesn't execute git commands - used for development |
| `-v`, `--verbose` | prints all executed git commands                    |
| `-h`, `--help`    | prints help menu                                    |

## Tips

- When prompted for selecting a co-author or a change type, you can start typing the name of your selection to filter results

- When prompted for a change scope or a commit message, on failure it deletes the message. You can use arrow up/down to go through your input history to bring your message back for editing

- You can edit the feature types, message length, whether or not you want to use scope, and edit the prompt/error messages safely in the **config.yml**

## Info

Commands that will be executed in your terminal from the script are:

| command                                        | usage                                                                            |
| ---------------------------------------------- | -------------------------------------------------------------------------------- |
| `git restore --staged <files>`                 | restores staged files                                                            |
| `git add <files>`                              | adds selected files for staging                                                  |
| `git status -s`                                | gets all files from git (untracked, staged, modified, renamed..)                 |
| `git diff --name-only --cached`                | gets only the changed tracked files                                              |
| `git commit -m <message>`                      | commits with a given message                                                     |
| `git branch --show-current`                    | gets the current branch                                                          |
| `git push`                                     | pushes to repository                                                             |
| `git push --set-upstream origin <branch_name>` | if pushing fails, sets the upstream to  have the same name as the current branch |
