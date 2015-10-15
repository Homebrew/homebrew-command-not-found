#!/usr/bin/env ruby

if (ARGV.first == "--fish")
	require "fileutils"
	file = File.expand_path("#{File.dirname(__FILE__)}/../handler.fish")
	
	if (ARGV[1] != nil)
		destination = File.expand_path(File.join(ARGV[1], "command-not-found.fish"))
	else
		destination = File.expand_path("~/.config/fish/functions/command-not-found.fish")
	end
	
	FileUtils.symlink(file, destination, :force => true)
else
	puts File.read(File.expand_path "#{File.dirname(__FILE__)}/../handler.sh")
end