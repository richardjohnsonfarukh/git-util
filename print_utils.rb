HEADING_LEN = 8

module PrintType
   STATUS = "status"
   COMMIT = "commit"
   DEBUG = "debugg"
   PUSH = "push"
   ERROR = "error"
   ADD = "gitadd"
   EXIT = "exit"
end

class Printer
   def initialize(print_commands, pastel)
      @print_commands = print_commands
      @p = pastel
   end

   def print(heading, prompt)
      puts (text(heading, prompt))
   end

   def commit_text(prompt)
      return text(PrintType::COMMIT, prompt)
   end

   def add(prompt)
      return text(PrintType::ADD, prompt)
   end

   def add_text(prompt)
      return text(PrintType::ADD, prompt)
   end

   def push(prompt)
      puts text(PrintType::PUSH, prompt)
   end

   def debug(prompt)
      puts text(PrintType::DEBUG, prompt)
   end

   def error(prompt)
      puts text(PrintType::ERROR, prompt)
   end

   def exit(prompt)
      puts text(PrintType::EXIT, prompt)
   end

   def text(heading, prompt)
      if heading.length >= HEADING_LEN - 1
         heading = heading[0, HEADING_LEN - 3] + "."
      end

      dashes_right = "-" * ((HEADING_LEN-heading.length) / 2)
      dashes_left = "-" * (HEADING_LEN-(heading.length+dashes_right.length))

      if @print_commands 
         if heading.eql? PrintType::ERROR
            heading_prnt = "\n[#{dashes_left}#{@p.red(PrintType::ERROR)}#{dashes_right}]"
         elsif heading.eql? PrintType::EXIT
            heading_prnt = "\n[#{dashes_left}#{@p.bright_blue(PrintType::EXIT)}#{dashes_right}]"
         else 
            heading_prnt = "\n[#{dashes_left}#{@p.cyan(heading)}#{dashes_right}]"
         end
      else
         if heading.eql? PrintType::ERROR
            heading_prnt = "#{@p.red.bold("!")}"
         elsif heading.eql? PrintType::DEBUG
            heading_prnt = "#{@p.magenta.bold("$")}"
         elsif heading.eql? PrintType::EXIT
            heading_prnt = "#{@p.bright_blue.bold("!")}"
         elsif heading.eql? PrintType::PUSH
            heading_prnt = "#{@p.green.bold("!")}"
         else
            heading_prnt = "#{@p.green.bold("?")}"
         end 
      end
      return "\n#{heading_prnt} #{@p.bold(prompt)}"
   end
end
