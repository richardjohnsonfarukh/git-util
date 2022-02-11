class Git
   require "tty-command"
   require "pastel"
   require 'optparse'
   require "yaml"
   require_relative "status"
   require_relative "questions"
   require_relative "commit"
   CONFIG_FILE_NAME = "config.yml"
   
   def initialize
      @cmd = TTY::Command.new(printer: TTY::Command::Printers::Null)
      @p = Pastel.new
      @print_commands = false
      @debug_mode = false
      $printer = Printer.new(@print_commands, @p)
      
      begin 
         @config = YAML.load(File.read(__dir__ + "/config/" + CONFIG_FILE_NAME))
         @commit_group = @config["commit"]["commit_groups"]["default"]
      rescue 
         $printer.error("No suitable config file \"#{CONFIG_FILE_NAME}\" has been found - exiting script")
         exit(false)
      end
      
      OptionParser.new do |parser|
         parser.banner = "Usage:" + __FILE__ + " [options]"
         parser.on("-a", "--all", "add all files in repository to staging") do 
            @add_all = true
         end
         parser.on("-v", "--verbose", "print command executions") do
            @print_commands = true
            @cmd = TTY::Command.new
         end
         parser.on("-d", "--debug", "debug mode - commands don't execute") do
            @debug_mode = true
         end
         parser.on("-r", "--ref REFS_TEXT", "overwrite the reference string with an argument") do |arg|
            @config["commit"]["refs_text"] = arg
         end
         parser.on("-s", "--simple", "run without scope, description, refs or co-author") do |arg|
            @commit_group = @config["commit"]["commit_groups"]["simple"]
         end
         parser.on("-f", "--full", "run with all possible questions") do |arg|
            @commit_group = @config["commit"]["commit_groups"]["full"]
         end
         parser.on("-c", "--custom NAME", "run a select commit group by name") do |arg|
            if @config["commit"]["commit_groups"].key?(arg)
               @commit_group = @config["commit"]["commit_groups"][arg]
            else
               $printer.error("Custom group '#{arg}' not found. Please refer to the 'config.yml'")
               exit(false)
            end
         end
         parser.on("-h", "--help", "prints this help") do
            puts parser
            exit(true)
         end

         begin
            parser.parse!
         rescue OptionParser::MissingArgument => e
            puts parser
            exit(false)
         end
      end

      $printer = Printer.new(@print_commands, @p)
      @questions = Questions.new(@config, @p)
   end
   
   def status
      begin 
         if @add_all
            run_command("git add -A")
         end
         all_files, e = @cmd.run("git status -s")
      rescue 
         $printer.exit(@config["exit"]["not_a_repo"])
         exit(false)
      end

      if all_files
         added_files, err = @cmd.run("git diff --name-only --cached")
         current_branch, err = @cmd.run("git branch --show-current")
         status = Status.new(all_files, added_files, current_branch)
      end

      unless status
         $printer.exit(@config["exit"]["no_files_selected"])
         exit(true)
      end
      
      return status
   end

   def add(status)
      unstaged, added = status.get_all_files()

      if (added.length + unstaged.length) == 0
         $printer.exit(@config["exit"]["no_files_to_commit"])
         exit(true)
      end
      
      unless @add_all
         files_to_stage = @questions.get_files_to_stage(added, unstaged)
      else
         $printer.add(@config["message"]["staged_files"])
         added.each do |file|
            puts "  #{@p.green(file)}"
         end
         return
      end
      
      files_to_restore = Array.new

      added.each do |file|
         unless files_to_stage.include? file
            files_to_restore << file
         end
      end

      unless files_to_restore.empty? 
         run_command("git restore --staged #{files_to_restore.join(" ")}")
      end 

      if files_to_stage.empty?
         $printer.exit(@config["exit"]["no_files_selected"])
         exit(true)
      else
         run_command("git add #{files_to_stage.join(" ")}")
         files_to_stage.each do |file|
            puts "  #{@p.green(file)}"
         end
      end
   end

   def commit
      commit = Commit::new(@commit_group, @questions)
      git_commit = commit.get_commit_message()

      begin
         run_command(git_commit)
      rescue
         $printer.error(@config["exit"]["commit_error"] % @p.yellow.bold(git_commit))
         exit(false)
      end 
   end

   def run_command(command)
      if @debug_mode
         $printer.debug(@p.yellow(command))
      else
         return @cmd.run(command)
      end
   end

   def push(status)
      begin 
         run_command("git push")
      rescue 
         begin 
            run_command("git push --set-upstream origin #{status.branch_name}")
         rescue
            $printer.error(@config["exit"]["push_error"])
            exit(false)
         end
      end

      unless @debug_mode
         $printer.push(@config["exit"]["push_successful"])
         
         unless ["main", "master"].include? status.branch_name
            $printer.push(@config["exit"]["raise_pr"] % @p.bold.blue(get_repo_link()))
         end
      end

   end

   def get_repo_link
      repo_url, e = @cmd.run("git config --get remote.origin.url")
      return "#{repo_url.strip.chomp(".git")}/pull/new/#{status.branch_name}"
   end
end
