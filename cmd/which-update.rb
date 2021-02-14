# frozen_string_literal: true

require "cli/parser"
require_relative "../lib/which_update"

module Homebrew
  module_function

  def which_update_args
    Homebrew::CLI::Parser.new do
      description <<~EOS
        Database update for `brew-which-formula`
      EOS
      switch "--stats",
             description: "print statistics about the database contents (number of commands and formulae, " \
                          "list of missing formulae)."
      switch "--commit",
             description: "commit the changes using `git`."
      conflicts "--stats", "--commit"
      named_args :database, max: 1
    end
  end

  def which_update
    args = which_update_args.parse

    if args.stats?
      Homebrew::WhichUpdate.stats source: args.named.first
    else
      Homebrew::WhichUpdate.update_and_save! source: args.named.first, commit: args.commit?
    end
  end
end
