# frozen_string_literal: true

require "cli/parser"
require_relative "../lib/which_formula"

module Homebrew
  module_function

  def which_formula_args
    Homebrew::CLI::Parser.new do
      usage_banner <<~EOS
        `which-formula` <command>

        Prints the formula(e) which provides the given command.
      EOS
      switch "--explain",
             description: "Output explanation of how to get 'cmd' by installing one of the providing formulae."
      min_named 1
    end
  end

  def which_formula
    args = which_formula_args.parse

    # NOTE: It probably doesn't make sense to use that on multiple commands since
    # each one might print multiple formulae
    args.named.each do |command|
      Homebrew::WhichFormula.which_formula command, explain: args.explain?
    end
  end
end
