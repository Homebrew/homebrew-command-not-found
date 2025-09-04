# typed: strict
# frozen_string_literal: true

require "abstract_command"
require_relative "../lib/which_update"

module Homebrew
  module Cmd
    class WhichUpdateCmd < AbstractCommand
      cmd_args do
        description <<~EOS
          Database update for `brew which-formula`.
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
        switch "--eval-all",
               description: "Evaluate all installed taps, rather than just the core tap."
        flag   "--max-downloads=",
               description: "Specify a maximum number of formulae to download and update."
        flag   "--summary-file=",
               description: "Output a summary of the changes to a file."
        conflicts "--stats", "--commit"
        conflicts "--stats", "--install-missing"
        conflicts "--stats", "--update-existing"
        conflicts "--stats", "--max-downloads"
        named_args :database, max: 1
      end

      sig { override.void }
      def run
        if args.stats?
          Homebrew::WhichUpdate.stats source: args.named.first
        else
          Homebrew::WhichUpdate.update_and_save! source:          args.named.first,
                                                 commit:          args.commit?,
                                                 update_existing: args.update_existing?,
                                                 install_missing: args.install_missing?,
                                                 max_downloads:   args.max_downloads&.to_i,
                                                 eval_all:        args.eval_all?,
                                                 summary_file:    args.summary_file
        end
      end
    end
  end
end
