# typed: true
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
        named_args :command, min: 1
      end

      def run
        # NOTE: It probably doesn't make sense to use that on multiple commands since
        # each one might print multiple formulae
        args.named.each do |command|
          Homebrew::WhichFormula.which_formula command, explain: args.explain?
        end
      end
    end
  end
end
