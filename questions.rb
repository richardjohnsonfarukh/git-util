require_relative "print_utils"
require "tty-prompt"

class Questions
   OTHER_CO_AUTHOR = "Other co-author"

   include PrintType

   def initialize(config, printer, pastel)
      @config = config
      @printer = printer
      @prompt = TTY::Prompt.new(interrupt: :exit)
      @p = pastel
   end

   def get_files_to_stage(added, unstaged)
      return @prompt.multi_select(@printer.add_text(@config["message"]["select_files"]), unstaged + added, cycle: true, echo: false, filter: true) do |menu|
         unless added.empty?
            menu.default *added
         end
      end
   end

   def get_commit_type
      if @config["commit"]["type"]
         commit_types = Hash.new
         @config["commit"]["types"].each do |type|
            commit_types[ "%-8.8s : #{type["description"]}" % type["name"]] = type["name"]
         end

         return @prompt.select(@printer.text(PrintType::COMMIT, @config["message"]["change_type"]), commit_types, cycle: true, filter: true)
      end
   end 

   # Ask about the commit message with a minimum length
   def get_commit_message(commit_type, commit_scope)
      max_message_length = @config["commit"]["max_message_length"] - (commit_scope ? commit_scope.length : 0  + commit_type.length)

      return @prompt.ask(@printer.text(PrintType::COMMIT, @config["message"]["commit_message"] % max_message_length)) do |q|
         q.validate(/^.{#{@config["commit"]["min_message_length"]},#{max_message_length}}$/,
            "Length has to be more than #{@config["commit"]["min_message_length"]} and less than #{max_message_length} characters")
         q.convert -> (i) do
            i[0] = i[0].downcase
            i.strip!
            return i
         end
      end
   end

   # Ask about the scope of the commit, if empty then skip
   def get_scope
      if @config["commit"]["scope"] 
         return @prompt.ask(@printer.text(PrintType::COMMIT, @config["message"]["scope"])) do |q|
            q.validate(/^.{0,#{@config["commit"]["scope_length"]}}$/,
               "Length can't be more than #{@config["commit"]["scope_length"]} characters")
            q.convert -> (i) do
               i.strip!
               return i
            end
         end
      end
      return ""
   end

   def get_description
      # Ask about a description message which will be styled as bullet points
      if @config["commit"]["description"] and @config["commit"]["max_description_length"] > 0
         description_lines = Array.new
         remaining_lines = @config["commit"]["max_description_length"]

         while remaining_lines > 0
            remaining_lines_color = @p.green.bold(remaining_lines)
            description_line = @prompt.ask(@printer.text(PrintType::COMMIT, @config["message"]["description_message"] % remaining_lines_color)) do |q|
               q.convert -> (i) do
                  i.strip!
                  return i
               end
            end

            if description_line
               description_lines << description_line
               remaining_lines -= 1
            else
               remaining_lines = 0
            end
         end
      end

      return description_lines
   end

   # Ask about the ticket reference in Github / Jira. If not enabled in config or empty, then skip
   def get_refs
      if @config["commit"]["refs"]
         refs_types = @config["commit"]["refs_types"]
         refs_text = @config["commit"]["refs_text"]

         reference_text = @config["message"]["refs_num"] % "#{@p.blue(refs_text)}#{@p.green.bold("<refs>")}"
         refs_num = @prompt.ask(@printer.text(PrintType::COMMIT, reference_text)) do |q|
            q.validate(/^[0-9]*/)
         end
         
         if refs_num
            if refs_types.length() > 1
               refs_type = @prompt.select(@printer.text(PrintType::COMMIT, @config["message"]["refs_type"]), refs_types, cycle: true, filter: true)
               refs = get_refs_text(refs_num, refs_type)
            else
               refs = get_refs_text(refs_num, refs_types[0])
            end
         end
      end

      return refs
   end

   def get_refs_text(refs_num, refs_type)
      return "#{refs_type}: #{@config["commit"]["refs_text"]}#{refs_num}\n"
   end

   # If co-authoring is enabled in the config, ask about the co-author if the answer
   def get_co_author
      if @config["commit"]["co_authoring"]
         use_co_author = @prompt.yes?(@printer.text(PrintType::COMMIT, @config["message"]["co_author_yes_no"]))
   
         if use_co_author
            commit_co_author = nil
            co_authors, co_authors_config = co_author_hash()

            unless co_authors.empty?
               commit_co_author = @prompt.select(@printer.text(PrintType::COMMIT, @config["message"]["co_author"]), co_authors, cycle: true, filter: true)

               if commit_co_author == OTHER_CO_AUTHOR 
                  commit_co_author = add_co_author(co_authors_config)
               end
            else 
               commit_co_author = add_co_author(co_authors_config)
            end 
         end
      end

      return commit_co_author
   end

   def add_co_author(co_authors)
      name = @prompt.ask(@printer.text(PrintType::COMMIT, @config["message"]["co_author_name"])) do |q|
         q.validate(/^[A-Z].*/)
         q.modify :strip
      end
      email = @prompt.ask(@printer.text(PrintType::COMMIT, @config["message"]["co_author_email"])) do |q|
         q.validate :email
         q.modify :strip
      end

      co_authors << { "name" => name, "email" => email }

      File.open(__dir__ + "/" + @config["commit"]["co_authoring_file"], "w") do |file|
         file.write(co_authors.to_yaml)
      end

      return "Co-authored-by: #{name} <#{email}>"
   end

   def co_author_hash()
      unless @config["commit"]["co_authoring_file"]
         return Hash.new
      end

      co_authors = YAML.load(File.read(__dir__ + "/" +  @config["commit"]["co_authoring_file"]))
      co_authors_hash = Hash.new

      unless co_authors
         return co_authors_hash, Array.new
      end

      co_authors.each do |auth| 
         co_authors_hash["#{auth["name"]} (#{auth["email"]})"] = "Co-authored-by: #{auth["name"]} <#{auth["email"]}>"
      end

      co_authors_hash[OTHER_CO_AUTHOR] = OTHER_CO_AUTHOR

      return co_authors_hash, co_authors
   end
end