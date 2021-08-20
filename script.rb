#!/usr/bin/ruby


class Git
   require "tty-command"
   require "tty-prompt"
   require "tty-file"
   require "pastel"
   require 'optparse'
   require "yaml"

   CONFIG_FILE_NAME = "config.yml"
   HEADING_LEN = 8
   STATUS = "status"
   COMMIT = "commit"
   PUSH = "push"
   ERROR = "error"
   ADD = "gitadd"
   EXIT = "exit"
   GIT = "git"

   def initialize
      @prompt = TTY::Prompt.new(interrupt: :exit)
      @cmd = TTY::Command.new(printer: TTY::Command::Printers::Null)
      @p = Pastel.new

      begin 
         @config = YAML.load(File.read(__dir__ + "/" + CONFIG_FILE_NAME))
      rescue 
         puts prompt(ERROR, "No suitable config file \"#{CONFIG_FILE_NAME}\" has been found")
         exit(false)
      end
      
      OptionParser.new do |parser|
         parser.banner = "Usage:" + __FILE__ + " [options]"
         parser.on("-a", "--all", "add all files in directory to staging") do |arg|
            @add_all = true
         end
         parser.on("-p", "--print", "print command executions") do |arg|
            @cmd = TTY::Command.new
         end
         parser.on("-h", "--help", "prints this help") do
            puts parser
            exit(true)
          end
      end.parse!
   end

   class Status
      attr_reader :branch_name
      attr_reader :added_files
      attr_reader :unstaged_files

      def initialize(unstaged_files, added_files, branch_name)

         @branch_name = branch_name
         @added_files = get_added(added_files)
         @unstaged_files = get_unstaged(unstaged_files)
      end

      def get_unstaged(unstaged_files)
         arr = Array.new
         unstaged_files = unstaged_files.split("\n")
         unstaged_files.each do |line|
            arr << line.split[1]
         end

         arr.delete_if do |file| 
            @added_files.include? file
         end
         return arr
      end

      def get_added(added_files)
         if added_files
            return added_files.split("\n")
         else 
            return Array.new
         end
      end

      def get_all_files
         return @unstaged_files, @added_files
      end

   end

   def add(status)

      #   1. Read the files from the status -s command 
      #   2. Select them with multi select or choose "select all"
      #   3. Go to commit stage

      unstaged, added = status.get_all_files()

      if (added.length + unstaged.length) == 0
         prompt(EXIT, "No files to be committed, exiting script")
         exit(true)
      end
      
      unless @add_all
         selected = @prompt.multi_select(prompt(ADD, "Select files to commit:"), unstaged + added, cycle: true) do |menu|
            unless added.empty?
               menu.default *added
            end
         end
      else
         return
      end
      

      files_to_stage = Array.new
      files_to_restore = Array.new

      selected.each do |file|
         unless added.include? file
            files_to_stage << file
         end
      end 

      added.each do |file|
         unless selected.include? file
            files_to_restore << file
         end
      end

      unless files_to_restore.empty? 
         @cmd.run("git restore --staged #{files_to_restore.join(" ")}")
      end 

      if selected.empty?
         puts prompt(EXIT, "No files have been added to staging area - exiting script")
         exit(true)
      else
         @cmd.run("git add #{files_to_stage.join(" ")}")
      end

   end

   def commit
      # (Future functionality - list also the files that have been added and restore them if unselected) from multiselect
      # Git commit (max 100char for message)
      #   1. List the files to be committed
      #   2. Read the plausible feature list and ask for a feature type - single select
      #   3. Ask for the scope for the feature as text - max 12 chars (optional) - 
      #   4. Ask for a description of the feature - first letter to lower case - validate not blank
      #   5. Ask for co author - multi select from existing list + new co author
      #   6. If new co author is chosen, validate email in string 
      #   7. Save to txt file with co authors
      #   8. Go to git push

      commit_types = @config["commit"]["types"]
      
      commit = "git commit -m "

   end

   # def print_commit_types(commit_types)

   # end

   def status_and_branch_name
      begin 
         if @add_all
            outout, e = @cmd.run("git add .")
         end

         all_files, e = @cmd.run("git status -s")

      rescue 
         puts prompt(STATUS, "Current directory is not in a repository - exiting script")
         exit(false)
      end

      if all_files
         added_files, err = @cmd.run("git diff --name-only --cached")
         current_branch, err = @cmd.run("git branch --show-current")
         status = Status.new(all_files, added_files, current_branch)
      end

      unless status
         exit(false)
      end
      
      return status
   end

   def push
      begin 
         current_branch, err = @cmd.run("git push")
      rescue 
         current_branch, err = @cmd.run("git branch --show-current")
         @cmd.run("git push --set-upstream origin #{current_branch}")
      end
   end

   def prompt(heading, prompt, err=false)
      if heading.length >= HEADING_LEN - 1
         heading = heading[0, HEADING_LEN - 3] + "."
      end

      dashes_right = "-" * ((HEADING_LEN-heading.length) / 2)
      dashes_left = "-" * (HEADING_LEN-(heading.length+dashes_right.length))

      if err
         return "[#{dashes_left}#{@p.red(ERROR)}#{dashes_right}] #{@p.bold(prompt)}"
      end
      
      return "[#{dashes_left}#{@p.blue(heading)}#{dashes_right}] #{@p.bold(prompt)}"
   end

end


def main
   git = Git.new
   status = git.status_and_branch_name()
   git.add(status)
   git.commit()
end 

main()