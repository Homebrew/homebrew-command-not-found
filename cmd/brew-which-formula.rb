#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-

# brew-which-formula: prints the formula which provides the given binary
#
# Usage:
#
#   brew which <command> [<command> ...]
#
#

require "shellwords"

# brew
require "extend/ARGV.rb"

LIST_PATH = File.expand_path("#{File.dirname(__FILE__)}/../executables.txt")

def matches(cmd)
  # We use 'grep' here not to read the whole file
  `grep #{Shellwords.escape cmd} #{LIST_PATH} 2>/dev/null`.chomp.split(/\n/)
end

def which_formula(cmd)
  cmd = cmd.downcase

  (matches cmd).each do |m|
    formula, cmds = m.split(":", 2)
    puts formula if !formula.nil? && !cmds.nil? && cmds.include?(cmd)
  end
end

ARGV.named.each { |cmd| which_formula cmd }
