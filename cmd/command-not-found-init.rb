# frozen_string_literal: true

require "abstract_command"
require "utils/shell"

module Homebrew
  module Cmd
    class CommandNotFoundInitCmd < AbstractCommand
      cmd_args do
        description <<~EOS
          Print instructions for setting up the command-not-found hook for your shell.
          If the output is not to a tty, print the appropriate handler script for your shell.
        EOS
        named_args :none
      end

      def run
        if $stdout.tty?
          help
        else
          init
        end
      end

      def shell
        Utils::Shell.parent || Utils::Shell.preferred
      end

      def init
        case shell
        when :bash, :zsh
          puts File.read(File.expand_path("#{File.dirname(__FILE__)}/../handler.sh"))
        when :fish
          puts File.expand_path "#{File.dirname(__FILE__)}/../handler.fish"
        else
          raise "Unsupported shell type #{shell}"
        end
      end

      def help
        case shell
        when :bash, :zsh
          puts <<~EOS
            # To enable homebrew-command-not-found
            # Add the following lines to ~/.#{shell}rc

            HB_CNF_HANDLER="$(brew --prefix)/Homebrew/Library/Taps/homebrew/homebrew-command-not-found/handler.sh"
            if [ -f "$HB_CNF_HANDLER" ]; then
              source "$HB_CNF_HANDLER";
            fi
          EOS
        when :fish
          puts <<~EOS
            # To enable homebrew-command-not-found
            # Add the following line to ~/.config/fish/config.fish

            set HB_CNF_HANDLER (brew --prefix)"/Homebrew/Library/Taps/homebrew/homebrew-command-not-found/handler.fish"
            if test -f $HB_CNF_HANDLER
              source $HB_CNF_HANDLER
            end
          EOS
        else
          raise "Unsupported shell type #{shell}"
        end
      end
    end
  end
end
