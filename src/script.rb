#!/usr/bin/ruby

require_relative "git"

def main
   git = Git.new
   git.status
   git.add
   git.commit
   git.push
end 

main()