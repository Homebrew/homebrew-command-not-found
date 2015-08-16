#!/usr/bin/env ruby
require "fileutils"

if (!ARGV.empty? and ARGV[0] == "--fish")
	file = File.expand_path("#{File.dirname(__FILE__)}/../handler.fish")
	destination = (ARGV[1] != nil) ? File.expand_path(File.join(ARGV[1], "command-not-found.fish")) : File.expand_path("~/.config/fish/functions/command-not-found.fish")

	FileUtils.symlink(file, destination)
else
	puts File.read(File.expand_path "#{File.dirname(__FILE__)}/../handler.sh")
end