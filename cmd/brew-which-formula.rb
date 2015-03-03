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

TAP_RE = %r(^.+?/[^/]+)
LIST_PATH = File.expand_path("#{File.dirname(__FILE__)}/../executables.txt")

def matches(cmd)
  # We use 'grep' here to speed up our search
  # TODO: benchmark subshell+grep vs. reading the file line-by-line in Ruby
  `grep #{Shellwords.escape cmd} #{LIST_PATH} 2>/dev/null`.chomp.split(/\n/)
end

def tapped?(tap)
  (HOMEBREW_LIBRARY/"Taps/#{tap}").directory?
end

def get_tap(formula)
  formula[TAP_RE]
end

# Filter a list of formulae by removing those from an untapped tap
def remove_not_tapped(formulae)
  formulae.select { |f| !f.include?("/") || tapped?(get_tap f) }
end

# Print a small text explaining how to get 'cmd' by installing 'formula'. Note
# that it'll still suggest to install the formula if it's already installed but
# unlinked.
def explain_formula_install(cmd, formula)
  instructions = []
  tap = get_tap formula
  instructions << "brew tap #{tap}" if tap && !tapped?(tap)
  instructions << "brew install #{formula}"

  puts <<-EOS
The program '#{cmd}' is currently not installed. You can install it by typing:
  #{instructions * "\n  "}
  EOS
end

# Print a small text explaining how to get 'cmd' by installing one of the given
# formulae.
def explain_formulae_install(cmd, formulae)
  return explain_formula_install(cmd, formulae.first) if formulae.size == 1
  # we don't support external formulae here for now since we'd need to explain
  # how to tap everything.
  formulae = remove_not_tapped(formulae)
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
