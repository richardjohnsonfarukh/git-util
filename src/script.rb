#!/usr/bin/ruby

require_relative "git"

def main
   git = Git.new
   status = git.status()
   git.add(status)
   git.commit(status)
   git.push(status)
end 

main()