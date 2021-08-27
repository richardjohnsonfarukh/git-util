#!/usr/bin/ruby
class Git
   require "tty-command"
   require "tty-prompt"
   require "pastel"
   require 'optparse'
   require "yaml"

   CONFIG_FILE_NAME = "config.yml"
   OTHER_CO_AUTHOR = "Other co-author"
   HEADING_LEN = 8
   STATUS = "status"
   COMMIT = "commit"
   DEBUG = "debugg"
   PUSH = "push"
   ERROR = "error"
   ADD = "gitadd"
   EXIT = "exit"
   GIT = "git"

   def initialize
      @prompt = TTY::Prompt.new(interrupt: :exit)
      @cmd = TTY::Command.new(printer: TTY::Command::Printers::Null)
      @p = Pastel.new
      @reader = TTY::Reader.new
      @print_commands = false
      @debug_mode = false

      begin 
         @config = YAML.load(File.read(__dir__ + "/" + CONFIG_FILE_NAME))
      rescue 
         puts prompt(ERROR, "No suitable config file \"#{CONFIG_FILE_NAME}\" has been found - exiting script")
         exit(false)
      end
      
      OptionParser.new do |parser|
         parser.banner = "Usage:" + __FILE__ + " [options]"
         parser.on("-a", "--all", "add all files in directory to staging") do |arg|
            @add_all = true
         end
         parser.on("-v", "--verbose", "print command executions") do |arg|
            @print_commands = true
            @cmd = TTY::Command.new
         end
         parser.on("-d", "--debug", "debug mode - commands don't execute") do
            @debug_mode = true
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
      unstaged, added = status.get_all_files()

      if (added.length + unstaged.length) == 0
         prompt(EXIT, @config["exit"]["no_files_to_commit"])
         exit(true)
      end
      
      unless @add_all
         selected = @prompt.multi_select(prompt(ADD, @config["message"]["select_files"]), unstaged + added, cycle: true, echo: false) do |menu|
            unless added.empty?
               menu.default *added
            end
         end
      else
         puts prompt(ADD, @config["message"]["staged_files"])
         added.each do |file|
            puts "  #{@p.green(file)}"
         end
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
         run_command("git restore --staged #{files_to_restore.join(" ")}")
      end 

      if selected.empty?
         puts prompt(EXIT, @config["exit"]["no_files_selected"])
         exit(true)
      else
         selected.each do |file|
            puts "  #{@p.green(file)}"
         end
         run_command("git add #{files_to_stage.join(" ")}")
      end

   end

   def commit
      commit_types = commit_type_hash()
      commit_type = @prompt.select(prompt(COMMIT, @config["message"]["change_type"]), commit_types, cycle: true, filter: true)

      commit_scope = @prompt.ask(prompt(COMMIT, @config["message"]["scope"])) do |q|
         q.validate(/^.{0,#{@config["commit"]["scope_length"]}}$/,
             "Length can't be more than #{@config["commit"]["scope_length"]} characters")
         q.convert -> (i) do
            i.strip!
            return i
         end
      end

      max_message_length = @config["commit"]["max_message_length"] - (commit_scope ? commit_scope.length : 0  + commit_type.length)

      commit_msg = @prompt.ask(prompt(COMMIT, @config["message"]["commit_message"] % max_message_length)) do |q|
         q.validate(/^.{#{@config["commit"]["min_message_length"]},#{max_message_length}}$/,
            "Length has to be more than #{@config["commit"]["min_message_length"]} and less than #{max_message_length} characters")
         q.convert -> (i) do
            i[0] = i[0].downcase
            i.strip!
            return i
         end
      end

      use_co_author = @prompt.yes?(prompt(COMMIT, @config["message"]["co_author_yes_no"]))

      if use_co_author
         commit_co_author = nil
         co_authors, co_authors_config = co_author_hash()

         unless co_authors.empty?
            commit_co_author = @prompt.select(prompt(COMMIT, @config["message"]["co_author"]), co_authors)

            if commit_co_author == OTHER_CO_AUTHOR 
               commit_co_author = add_co_author(co_authors_config)
            end
         else 
            commit_co_author = add_co_author(co_authors_config)
         end 
      end

      git_commit = build_commit(commit_type, commit_scope, commit_msg, commit_co_author)

      begin
         run_command(git_commit)
      rescue
         puts prompt(ERROR, @config["exit"]["commit_error"] % @p.yellow.bold(git_commit))
         exit(false)
      end 
   end

   def build_commit(type, scope, msg, co_author)
      msg = process_msg_or_scope(msg)
      scope = process_msg_or_scope(scope, isScope: true)

      if co_author
         co_author = co_author.prepend("\n\n")
      else
         co_author = ""
      end

      return "git commit -m \"#{type}#{scope}: #{msg}#{co_author}\""
   end

   def run_command(command)
      if @debug_mode
         puts prompt(DEBUG, @p.yellow(command))
      else
         @cmd.run(command)
      end
   end

   def commit_type_hash()
      commit_type_hash = Hash.new
      @config["commit"]["types"].each do |type|
         commit_type_hash[ "#{type["name"]}: #{type["description"]}" ] = type["name"]
      end
      
      return commit_type_hash
   end

   def process_msg_or_scope(str, isScope: false)
      if isScope and (!str or str == "")
         return ""
      end

      if str and str[-1].match(/\.|!|\?/) and str.length > 2
         str = str[0..-2]
      end

      if isScope
         str = "(#{str})"
      end

      return str
   end


   def co_author_hash()
      unless @config["commit"]["co_authoring_file"]
         return Hash.new
      end

      co_authors = YAML.load(File.read(__dir__ + "/" +  @config["commit"]["co_authoring_file"]))
      co_authors_hash = Hash.new

      co_authors.each do |auth| 
         co_authors_hash["#{auth["name"]} (#{auth["email"]})"] = "Co-authored-by: #{auth["name"]} <#{auth["email"]}>"
      end

      co_authors_hash[OTHER_CO_AUTHOR] = OTHER_CO_AUTHOR

      return co_authors_hash, co_authors
   end

   def add_co_author(co_authors)
      name = @prompt.ask(prompt(COMMIT, @config["message"]["co_author_name"])) do |q|
         q.validate(/^[A-Z].*/)
         q.modify :strip
      end
      email = @prompt.ask(prompt(COMMIT, @config["message"]["co_author_email"])) do |q|
         q.validate :email
         q.modify :strip
      end

      co_authors << { "name" => name, "email" => email }
      File.open(@config["commit"]["co_authoring_file"], "w") do |file|
         file.write(co_authors.to_yaml)
      end

      return "Co-authored-by: #{name} <#{email}>"
   end

   def status_and_branch_name
      begin 
         if @add_all
            run_command("git add .")
         end

         all_files, e = @cmd.run("git status -s")

      rescue 
         puts prompt(STATUS, @config["exit"]["not_a_repo"])
         exit(false)
      end

      if all_files
         added_files, err = @cmd.run("git diff --name-only --cached")
         current_branch, err = @cmd.run("git branch --show-current")
         status = Status.new(all_files, added_files, current_branch)
      end

      unless status
         puts prompt(ERROR, @config["exit"]["no_files_selected"])
         exit(true)
      end
      
      return status
   end

   def push
      begin 
         run_command("git push")
      rescue 
         current_branch, err = @cmd.run("git branch --show-current")
         run_command("git push --set-upstream origin #{current_branch}")
      end
   end

   def prompt(heading, prompt, err=false)
      if heading.length >= HEADING_LEN - 1
         heading = heading[0, HEADING_LEN - 3] + "."
      end

      dashes_right = "-" * ((HEADING_LEN-heading.length) / 2)
      dashes_left = "-" * (HEADING_LEN-(heading.length+dashes_right.length))

      if err
         return "\n[#{dashes_left}#{@p.red(ERROR)}#{dashes_right}] #{@p.bold(prompt)}"
      end
      
      return "\n[#{dashes_left}#{@p.blue(heading)}#{dashes_right}] #{@p.bold(prompt)}"
   end
end

def main
   git = Git.new
   status = git.status_and_branch_name()
   git.add(status)
   git.commit()
   git.push()
end 

main()