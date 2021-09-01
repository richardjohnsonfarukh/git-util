#!/usr/bin/ruby

require 'optparse'
require_relative "git"

def main
   git = Git.new
   status = git.status_and_branch_name()
   git.add(status)
   git.commit()
   git.push(status)
end 

main()