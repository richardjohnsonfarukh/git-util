class Commit 
   require_relative "questions"
   
   module QuestionTypes 
      SCOPE = "scope"
      DESCRIPTION = "description"
      REFS = "refs"
      CO_AUTHOR = "co_author"
      MULTI_CO_AUTHOR = "multi_co_authors"
   end 

   def initialize(commit_group, questions)
      # based on this one, we will select which commit type we want to use 
      # should be set on from the parser based on flags instead of here (and will have the value
      # of the selected config)
      @commit_group = commit_group
      @q = questions
   end
   
   # the last 5-10 commits should be saved in a FIFO
   # queue, so that the card numbers are selectable
   # 
   # alternatively, this can be used to autofill in the last
   # co-author and card number based on a selected flag
   # (will print those out before asking for a commit message)
   def process_recent_commits
      
   end


   def get_commit_message
      type = @q.get_commit_type

      if @commit_group.include? QuestionTypes::SCOPE
         scope = @q.get_scope
      end

      msg = @q.get_commit_message(type, scope)

      if @commit_group.include? QuestionTypes::DESCRIPTION
         description = @q.get_description
      end

      if @commit_group.include? QuestionTypes::REFS
         # - if refs is an empty flag, ask the question regardless
         #   of the commit config
         # - if refs is a flag with a value or we are pulling values from 
         #   old commits, then don't ask a question but assume a value
         # - otherwise, if it is in the config for the current type, ask the question
         refs_type, refs_text, refs_num = @q.get_refs
      end

      if @commit_group.include? QuestionTypes::MULTI_CO_AUTHOR
         co_authors = @q.get_multi_co_authors
      elsif  @commit_group.include? QuestionTypes::CO_AUTHOR
         co_authors = @q.get_co_author
      end

      return get_commit_string(
         type, 
         scope, 
         msg, 
         description, 
         co_authors, 
         refs_type,
         refs_text,
         refs_num
      )
   end

   # should add the most recent commit to the queue in a file within
   # a temporary folder
   def save_commit
      
   end

   def get_commit_string(type, scope, msg, desc, co_authors, refs_type, refs_text, refs_num)
      msg = process_msg_or_scope(msg)
      scope = process_msg_or_scope(scope, is_scope: true)
      desc = process_description(desc)
      co_authors = process_co_authors(co_authors)
      refs = process_refs(refs_type, refs_text, refs_num)

      desc.concat("\n\n") if !co_authors.empty? or !refs.empty?

      return "git commit -m \"#{type}#{scope}: #{msg}#{desc}#{refs}#{co_authors}\""
   end

   # TODO include this method
   def process_refs(refs_type, refs_text, refs)
      return refs.nil? || refs.empty? ? "" : "#{refs_type}: #{refs_text}#{refs_num}\n"
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