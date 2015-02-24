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
  `grep -m 1 #{Shellwords.escape cmd} #{LIST_PATH} 2>/dev/null`.chomp.split(/\n/)
end

def which_formula(cmd)
  cmd = cmd.downcase

  (matches cmd).each do |m|
    formula, cmds_text = m.split(":", 2)
    next if formula.nil? || cmds_text.nil?
    cmds = cmds_text.split(" ")
    puts formula if !cmds.nil? && cmds.include?(cmd)
  end
end

ARGV.named.each { |cmd| which_formula cmd }
