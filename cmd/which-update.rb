require "cli/parser"
require_relative "../lib/which_update"

module Homebrew
  module_function

  def which_update_args
    Homebrew::CLI::Parser.new do
      usage_banner <<~EOS
        `which-update` [<database>]

        Database update for `brew-which-formula`
      EOS
      switch "--stats",
             description: "print statistics about the database contents (number of commands and formulae, " \
                          "list of missing formulae)."
      switch "--commit",
             description: "commit the changes using `git`."
      conflicts "--stats", "--commit"
      max_named 1
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
