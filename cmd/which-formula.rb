# frozen_string_literal: true

require "cli/parser"
require_relative "../lib/which_formula"

module Homebrew
  module_function

  def which_formula_args
    Homebrew::CLI::Parser.new do
      description <<~EOS
        Show which formula(e) provides the given command.
      EOS
      switch "--explain",
             description: "Output explanation of how to get <command> by installing one of the providing formulae."
      named_args :command, min: 1
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
