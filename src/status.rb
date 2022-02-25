class Status
   attr_reader :branch_name
   attr_reader :added_files
   attr_reader :unstaged_files
   attr_reader :repo_url

   def initialize(unstaged_files, added_files, branch_name, repo_url)
      @added_files = process_added(added_files)
      @unstaged_files = process_unstaged(unstaged_files)
      @branch_name = branch_name.strip
      @repo_url = repo_url
   end

   def process_unstaged(unstaged_files)
      arr = Array.new
      unstaged_files = unstaged_files.split("\n")

      unstaged_files.each do |line|
         unless line.split.length == 4
            arr << line.split[1]
         end
      end

      arr.delete_if do |file| 
         @added_files.include? file 
      end
      return arr
   end

   def process_added(added_files)
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