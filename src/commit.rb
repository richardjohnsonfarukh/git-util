class Commit 
   require_relative "questions"
   require "yaml"
   
   module QuestionTypes 
      SCOPE = "scope"
      DESCRIPTION = "description"
      REFS = "refs"
      CO_AUTHOR = "co_author"
      MULTI_CO_AUTHOR = "multi_co_authors"
   end 

   PREVIOUS_COMMIT_FILE = "/../.cache/previous_commit.yml"

   def initialize(commit_group, questions, status)
      @commit_group = commit_group
      @q = questions
      @status = status
   end
   
   # the last 5-10 commits should be saved in a FIFO
   # queue, so that the card numbers are selectable
   # 
   # alternatively, this can be used to autofill in the last
   # co-author and card number based on a selected flag
   # (will print those out before asking for a commit message)
   def process_recent_commits
      # previous_props = YAML.load(File.read(__dir__ + PREVIOUS_COMMIT_FILE))
   end

   def get_commit_message
      commit_props = Hash.new

      commit_props[:type] = @q.get_commit_type

      if @commit_group.include? QuestionTypes::SCOPE
         commit_props[:scope] = @q.get_scope
      end

      commit_props[:msg] = @q.get_commit_message(commit_props[:type], commit_props[:scope])

      if @commit_group.include? QuestionTypes::DESCRIPTION
         commit_props[:description] = @q.get_description
      end

      if @commit_group.include? QuestionTypes::REFS
         # - if refs is an empty flag, ask the question regardless
         #   of the commit config
         # - if refs is a flag with a value or we are pulling values from 
         #   old commits, then don't ask a question but assume a value
         # - otherwise, if it is in the config for the current type, ask the question
         commit_props.merge!(@q.get_refs)
      end

      if @commit_group.include? QuestionTypes::MULTI_CO_AUTHOR
         commit_props[:co_authors] = @q.get_multi_co_authors
      elsif  @commit_group.include? QuestionTypes::CO_AUTHOR
         commit_props[:co_authors] = @q.get_co_author
      end

      save_commit(commit_props)

      return get_commit_string(commit_props)
   end

   def save_commit(commit_props)
      begin
         previous_props = YAML.load(File.read(__dir__ + PREVIOUS_COMMIT_FILE))
         previous_props.pop() if previous_props.length == 5
      rescue
         previous_props = Array.new
      end

      commit_props[:repo_url => @status.repo_url]
      commit_props[:branch_name => @status.branch_name]
      previous_props.unshift(commit_props)
      
      File.write(__dir__ + PREVIOUS_COMMIT_FILE, YAML.dump(previous_props))
   end

   def get_commit_string(commit_props)
      type = commit_props[:type]
      scope = process_msg_or_scope(commit_props[:scope], is_scope: true)
      msg = process_msg_or_scope(commit_props[:msg])
      desc = process_description(commit_props[:description])
      co_authors = process_co_authors(commit_props[:co_authors])
      refs = process_refs(
         commit_props[:refs_type],
         commit_props[:refs_text],
         commit_props[:refs_num]
      )

      desc.concat("\n\n") if !co_authors.empty? or !refs.empty?

      return "git commit -m \"#{type}#{scope}: #{msg}#{desc}#{refs}#{co_authors}\""
   end

   def process_refs(refs_type, refs_text, refs_num)
      return refs_num.nil? || refs_num.empty? ? "" : "#{refs_type}: #{refs_text}#{refs_num}\n"
   end

   def process_co_authors(co_authors)
      return co_authors.nil? || co_authors.empty? ? "" : "Co-authored-by: " + co_authors.join(", ")
   end

   def process_description(description_array)
      return description_array.nil? || description_array.empty? ? "" : "\n\n- " + description_array.join("\n- ")
   end

   def process_msg_or_scope(str, is_scope: false)
      return "" if str.nil? || str.empty?

      if str and str.length > 2 and str[-1].match(/\.|!|\?/)
         str = str[0..-2]
      end
      
      return is_scope ? "(#{str})" : str 
   end
end
