# typed: strict
# frozen_string_literal: true

require "abstract_command"
require_relative "../lib/which_formula"

module Homebrew
  module Cmd
    class WhichFormulaCmd < AbstractCommand
      cmd_args do
        description <<~EOS
          Show which formula(e) provides the given command.
        EOS
        switch "--explain",
               description: "Output explanation of how to get <command> by installing one of the providing formulae."
        switch "--skip-update",
               description: "Skip updating the executables database if any version exists on disk, no matter how old."
        named_args :command, min: 1
      end

      sig { override.void }
      def run
        # NOTE: It probably doesn't make sense to use that on multiple commands since
        # each one might print multiple formulae
        args.named.each do |command|
          Homebrew::WhichFormula.which_formula command, explain: args.explain?, skip_update: args.skip_update?
        end
      end
    end
  end
end
