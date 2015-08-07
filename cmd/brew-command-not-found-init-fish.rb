
require "fileutils"

file = File.expand_path("#{File.dirname(__FILE__)}/../handler.fish")
destination = ARGV[0] ? ARGV[0]+"command-not-found.fish" : File.expand_path("~/.config/fish/functions/command-not-found.fish")

FileUtils.cp(file, destination)
