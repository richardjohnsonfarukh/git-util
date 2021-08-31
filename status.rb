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