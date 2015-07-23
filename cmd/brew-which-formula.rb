#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-

# brew-which-formula: prints the formula(e) which provides the given command
#
# Usage:
#
#   brew which <command>
#
#

# brew
require "extend/ARGV.rb"

TAP_RE = %r(^.+?/[^/]+)
LIST_PATH = File.expand_path("#{File.dirname(__FILE__)}/../executables.txt")

def matches(cmd)
  # We use 'grep' here to speed up our search
  # TODO: benchmark grep vs. reading the file line-by-line in Ruby
  Utils.popen_read("grep", cmd, LIST_PATH).chomp.split(/\n/)
end

# Print a small text explaining how to get 'cmd' by installing 'formula'. Note
# that it'll still suggest to install the formula if it's already installed but
# unlinked.
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
  puts <<-EOS.undent
    The program '#{cmd}' can be found in the following formulae:
      * #{formulae * "\n      * "}
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

  return if formulae.empty?

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
