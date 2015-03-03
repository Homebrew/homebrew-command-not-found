#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-

# brew-which-formula: prints the formula(e) which provides the given command
#
# Usage:
#
#   brew which <command>
#
#

require "shellwords"

# brew
require "extend/ARGV.rb"

LIST_PATH = File.expand_path("#{File.dirname(__FILE__)}/../executables.txt")

def matches(cmd)
  # We use 'grep' here to speed up our search
  # TODO: benchmark subshell+grep vs. reading the file line-by-line in Ruby
  `grep #{Shellwords.escape cmd} #{LIST_PATH} 2>/dev/null`.chomp.split(/\n/)
end

# Print a small text explaining how to get 'cmd' by installing 'formula'
def explain_formula_install(cmd, formula)
  puts <<-EOS
The program '#{cmd}' is currently not installed. You can install it by typing:
  brew install #{formula}
  EOS
end

# Print a small text explaining how to get 'cmd' by installing one of the given
# formulae.
def explain_formulae_install(cmd, formulae)
  return explain_formula_install(cmd, formulae.first) if formulae.size == 1
  puts <<-EOS
The program '#{cmd}' can be found in the following formulae:
  * #{formulae * "\n  * "}
Try: brew install <selected formula>
  EOS
end

# if 'explain' is false, print all formulae that can be installed to get the
# given command. If it's true, print them in human-readable form with an help
# text.
def which_formula(cmd, explain=false)
  cmd = cmd.downcase

  formulae = (matches cmd).map do |m|
    formula, cmds_text = m.split(":", 2)
    next if formula.nil? || cmds_text.nil?
    cmds = cmds_text.split(" ")
    formula if !cmds.nil? && cmds.include?(cmd)
  end.compact

  if explain
    explain_formulae_install(cmd, formulae)
  else
    puts formulae * "\n"
  end
end

explain = ARGV.flag? "--explain"
# Note: It probably doesn't make sense to use that on multiple commands since
# each one might print multiple formulae
ARGV.named.each { |cmd| which_formula cmd, explain }
