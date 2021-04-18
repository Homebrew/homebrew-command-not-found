# frozen_string_literal: true

require "cli/parser"
require_relative "../lib/which_update"

module Homebrew
  module_function

  def which_update_args
    Homebrew::CLI::Parser.new do
      description <<~EOS
        Database update for `brew which-formula`
      EOS
      switch "--stats",
             description: "Print statistics about the database contents (number of commands and formulae, " \
                          "list of missing formulae)."
      switch "--commit",
             description: "Commit the changes using `git`."
      switch "--update-existing",
             description: "Update database entries with outdated formula versions."
      switch "--install-missing",
             description: "Install and update formulae that are missing from the database and don't have bottles."
      flag   "--max-downloads=",
             description: "Specify a maximum number of formulae to download and update."
      conflicts "--stats", "--commit"
      conflicts "--stats", "--install-missing"
      conflicts "--stats", "--update-existing"
      conflicts "--stats", "--max-downloads"
      named_args :database, max: 1
    end
  end

  def which_update
    args = which_update_args.parse

    if args.stats?
      Homebrew::WhichUpdate.stats source: args.named.first
    else
      Homebrew::WhichUpdate.update_and_save! source: args.named.first, commit: args.commit?,
                                             update_existing: args.update_existing?,
                                             install_missing: args.install_missing?,
                                             max_downloads: args.max_downloads
    end
  end
end
