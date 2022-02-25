# Git Utils!

## Intro
This project has the following goals:

1. Circumvent copy and pasting file names that you want to add to the staging area
2. Keep a convention for commit messages
3. Add bullet points for longer messages and references to issues in Git/Jira
4. Easily add co-authors you have previously worked with
5. Automatically push and set your upstream to have the same name as your current branch if your push fails

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

| options                | function                                                |
| ---------------------- | ------------------------------------------------------- |
| `-a`, `--all`          | adds all git files before executing                     |
| `-d`, `--debug`        | doesn't execute git commands - used for development     |
| `-v`, `--verbose`      | prints all executed git commands                        |
| `-s`, `--simple`       | run without scope, description, refs or co-author       |
| `-f`, `--full`         | run with all possible questions                         |
| `-c`, `--custom NAME`  | run a select commit group by name                       |
| `-r`, `--ref REF_TEXT` | overwrite the reference string with an argument         |
| `-n`, `--num REFS_NUM` | specify the reference number (takes priority over --ref |
| `-h`, `--help`         | prints help menu                                        |

The script will build a commit in the following style:

```bash

$ git commit -m "feat(scope): commit message

- first line of description
- second line of description

Refs: <your-team>-123
Co-authored-by: Author <author@email.uk>"

```

## Tips

- When prompted for selecting a co-author or a change type, you can start typing the name of your selection to filter results

- When prompted for a change scope or a commit message, on failure it deletes the message. You can use arrow up/down to go through your input history to bring your message back for editing

- You can edit the feature types, message length, whether or not you want to use scope, and edit the prompt/error messages safely in the **config.yml**

## Config

- The script brings rich customization of the questions that get asked, the ref types, the texts etc.
- You can modify them freely using the `config.yml`
```yaml
--- 
commit:
  # custom commit groups you can add to, and reference using the -c flag
  # at the minimum, groups will ask for a feature type and a commit message
  # accepted group members are: [scope, description, refs, co_author, multi_co_authors]
  commit_groups:
    # this group will be used if no group parameters are specified (--custom, --full, --simple)
    default: [scope, description, refs, co_author]

    # this group will be used if the --full flag is specified
    full: [scope, description, refs, multi_co_authors]

    # this group will be used if the --simple flag is specified 
    simple: []

  # possible ref types from the selector - if only one is listed in the config, it will always be selected by default
  refs_types: ["Refs", "Fixes", "Closes"]

  # text which will be apended to the selected ref type - use this to reference Jira or GitHub stories by number
  refs_text: "<your-team>-"

  # minimum accepted commit message length
  min_message_length: 5

  # maximum character length for the main message
  max_message_length: 100

  # maximum number of bullet points for a description
  max_description_length: 5

  # maximum character length for the scope of the commit
  max_scope_length: 15

  # name of the referenced co-authoring file (found in src/configs)
  co_authoring_file: co-authors.yml

  # all the types of commit in the prompt and their descriptions
  types:
    - name: feat
      description: A new feature
    - name: fix 
      description: A bug fix
    - name: style
      description: Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)
    - name: test 
      description: Adding missing tests or correcting existing tests
    - name: refactor
      description:  A code change that neither fixes a bug nor adds a feature
    - name: build
      description: "Changes that affect the build system or external dependencies (example scopes: gulp, broccoli, npm)"
    - name: ci
      description: "Changes to our CI configuration files and scripts (example scopes: Travis, Circle, BrowserStack, SauceLabs)"
    - name: chore 
      description: Other changes that don't modify src or test files
    - name: revert
      description: Reverts a previous commit
    - name: docs
      description: Documentation only changes

# message prompt texts. 
message:
    select_files: "Select files to commit:"
    staged_files: "Selected files to commit:"
    change_type: "Select change type:"
    scope: "What is the scope of this change? (enter to skip)"

    # %d will reference the max_message_length and needs to be included in some form for interpolation
    commit_message: "Enter a commit message: (max %d chars)"

    # %s will reference the max_description_length and needs to be included in some form for interpolation
    description_message: "Enter extra details - %s lines remaining (enter to finish):"

    # %s will reference the refs_text and needs to be included in some form for interpolation
    refs_num: "Enter a reference to your ticket %s (enter to skip):"
    refs_type: "What is the type of reference?"
    co_author_yes_no: "Would you like to add a co-author"
    co_author: "Who is your co-author?"
    multi_co_authors: "Who are your co-authors?"
    co_author_name: "What is your co-author's name?"
    co_author_email: "What is your co-author's email address?"

# text displayed on error or before exiting the script
exit:
    not_a_repo: Current directory is not in a repository - exiting script
    no_files_selected: No files selected for staging area - exiting script
    no_files_to_commit: No modified files, nothing to commit - exiting script
    commit_error: "Unexpected error while trying to perform: \n  %s"
    push_error: Could not push to remote, check your permissions - exiting script
    push_successful: Successfully pushed to remote.
    # %s is the link to create a pull request for the current branch
    raise_pr: Raise a pull request on %s

```
## Info

The script util aims to only make changes within its own directory, and it only modifies and creates `src/config/co-authors.yml` and `.cache/previous_commit.yml`.

NOTE: There is a growth limit of 15 commits on `.cache/previous_commit.yml`, however there are no limits on creating new co-authors!

Commands that will be executed in your terminal from the script are:

| command                                        | usage                                                                            |
| ---------------------------------------------- | -------------------------------------------------------------------------------- |
| `git status -s`                                | gets all files from git (untracked, staged, modified, renamed..)                 |
| `git diff --name-only --cached`                | gets only the changed tracked files                                              |
| `git branch --show-current`                    | gets the current branch                                                          |
| `git config --local remote.origin.url`         | gets the link to the remote repository                                           |
| `git add <files>`                              | adds selected files for staging                                                  |
| `git add -A`                                   | adds all files in the repo                                                       |
| `git restore --staged <files>`                 | restores staged files                                                            |
| `git commit -m <message>`                      | commits with a given message                                                     |
| `git push`                                     | pushes to repository                                                             |
| `git push --set-upstream origin <branch_name>` | if pushing fails, sets the upstream to  have the same name as the current branch |
