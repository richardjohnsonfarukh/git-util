class Questions
   require_relative "print_utils"
   require "tty-prompt"
   include PrintType

   OTHER_CO_AUTHOR = "Other co-author"

   def initialize(config, pastel)
      @config = config
      @prompt = TTY::Prompt.new(interrupt: :exit)
      @p = pastel
   end

   def get_files_to_stage(added, unstaged)
      return @prompt.multi_select($printer.add_text(@config["message"]["select_files"]), unstaged + added, cycle: true, echo: false, filter: true) do |menu|
         unless added.empty?
            menu.default *added
         end
      end
   end

   def get_commit_type
      commit_types = Hash.new
      @config["commit"]["types"].each do |type|
         commit_types[ "%-8.8s : #{type["description"]}" % type["name"]] = type["name"]
      end

      return @prompt.select($printer.commit_text(@config["message"]["change_type"]), commit_types, cycle: true, filter: true)
   end 

   def get_commit_message(commit_type, commit_scope)
      max_message_length = @config["commit"]["max_message_length"] - (commit_scope ? commit_scope.length : 0  + commit_type.length)

      return @prompt.ask($printer.commit_text(@config["message"]["commit_message"] % max_message_length)) do |q|
         q.validate(/^.{#{@config["commit"]["min_message_length"]},#{max_message_length}}$/,
            "Length has to be more than #{@config["commit"]["min_message_length"]} and less than #{max_message_length} characters")
         q.convert -> (i) do
            i[0] = i[0].downcase
            i.strip!
            return i
         end
      end
   end

   def get_scope
      return @prompt.ask($printer.commit_text(@config["message"]["scope"])) do |q|
         q.validate(/^.{0,#{@config["commit"]["max_scope_length"]}}$/,
            "Length can't be more than #{@config["commit"]["max_scope_length"]} characters")
         q.convert -> (i) do
            i.strip!
            return i
         end
      end
   end

   def get_description
      description_lines = Array.new
      remaining_lines = @config["commit"]["max_description_length"]

      while remaining_lines > 0
         remaining_lines_color = @p.green.bold(remaining_lines)
         description_line = @prompt.ask($printer.commit_text(@config["message"]["description_message"] % remaining_lines_color)) do |q|
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

      return description_lines
   end

   def get_refs
      refs_types = @config["commit"]["refs_types"]
      refs_text = @config["commit"]["refs_text"]

      if $options[:refs_num].nil? 
         reference_text = @config["message"]["refs_num"] % "#{@p.blue(refs_text)}#{@p.green.bold("<refs>")}"
         refs_num = @prompt.ask($printer.commit_text(reference_text)) do |q|
            q.validate(/^[0-9]*/)
         end
      else
         refs_num = $options[:refs_num]
      end
      
      if refs_num
         if refs_types.length() > 1
            refs_type = @prompt.select($printer.commit_text(@config["message"]["refs_type"]), refs_types, cycle: true, filter: true)
         else
            refs_type = refs_types[0]
         end
      end

      return {:refs_type => refs_type, :refs_text => @config["commit"]["refs_text"], :refs_num => refs_num}
   end

   def get_co_author
      use_co_author = @prompt.yes?($printer.commit_text(@config["message"]["co_author_yes_no"]))      
      return Array.new unless use_co_author

      co_authors, co_authors_config = co_author_hash()

      unless co_authors.empty?
         commit_co_author = @prompt.select($printer.commit_text(@config["message"]["co_author"]), co_authors, cycle: true, filter: true)

         if commit_co_author == OTHER_CO_AUTHOR 
            commit_co_author = add_co_author(co_authors_config)
         end
      else 
         commit_co_author = add_co_author(co_authors_config)
      end 

      return [commit_co_author]
   end

   def get_multi_co_authors
      co_authors, co_authors_config = co_author_hash()

      unless co_authors.empty?
         commit_co_authors = @prompt.multi_select($printer.commit_text(@config["message"]["multi_co_authors"]), co_authors, cycle: true, filter: true)

         if commit_co_authors.include? OTHER_CO_AUTHOR 
            commit_co_authors << add_co_author(co_authors_config)
         end
      end

      return commit_co_authors
   end

   def add_co_author(co_authors)
      name = @prompt.ask($printer.commit_text(@config["message"]["co_author_name"])) do |q|
         q.validate(/^[A-Z].*/)
         q.modify :strip
      end
      email = @prompt.ask($printer.commit_text(@config["message"]["co_author_email"])) do |q|
         q.validate :email
         q.modify :strip
      end

      co_authors << { "name" => name, "email" => email }
      
      File.open(__dir__ + "/config/" + @config["commit"]["co_authoring_file"], "w") do |file|
         file.write(co_authors.to_yaml)
      end

      return "#{name} <#{email}>"
   end

   def co_author_hash
      unless @config["commit"]["co_authoring_file"]
         return Hash.new
      end

      begin 
         co_authors = YAML.load(File.read(__dir__ + "/config/" +  @config["commit"]["co_authoring_file"]))
      rescue
         return Hash.new
      end

      co_authors_hash = Hash.new

      unless co_authors
         return co_authors_hash, Array.new
      end

      co_authors.each do |auth| 
         co_authors_hash["#{auth["name"]} (#{auth["email"]})"] = "#{auth["name"]} <#{auth["email"]}>"
      end

      co_authors_hash[OTHER_CO_AUTHOR] = OTHER_CO_AUTHOR

      return co_authors_hash, co_authors
   end
end
