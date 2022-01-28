require 'fileutils'
require "tty-command"
require 'yaml'
require 'digest'

CONFIG = __dir__ + "/config.yml"
CO_AUTHORS = __dir__ + "/co-authors.yml"
CHECKSUM_FILE = __dir__ + "/checksums.yml"

def copy_config()
   unless File.file?(CONFIG)
      FileUtils.cp("config_template.yml", "config.yml")
   end
end

def verify_co_authors()
   begin
      co_authors = YAML.parse(File.open(CO_AUTHORS))
   rescue => exception
      puts "Could not parse 'co-authors.yml'. Exiting script"
   end

   output, err = @cmd.run("sha256sum #{CONFIG}")
end

def verify_config()
   begin
      config = YAML.parse(File.open(CONFIG))
   rescue => exception
      puts "Could not parse 'config.yml'. Exiting script"
   end

   output, err = @cmd.run("sha256sum #{CONFIG}")
   puts output.split(" ")[0]

end

def verify()
   @cmd = TTY::Command.new(printer: TTY::Command::Printers::Null)
   verify_co_authors()
   verify_config()
end

def verify_checksum(filename)
   unless File.file?(filename)
      puts "#{filename} not found, exiting script"
   end

   unless File.file?(CON)
end

   
verify()