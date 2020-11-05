#!/usr/bin/env ruby
# frozen_string_literal: true

require "utils/shell"

def shell
  Utils::Shell.parent || Utils::Shell.preferred
end

def help
  case shell
  when :bash
    puts <<~EOS
      # To enable homebrew-command-not-found
      # Add the following lines to ~/.bashrc

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
  when :zsh
    puts <<~EOS
      # To enable homebrew-command-not-found
      # Add the following lines to ~/.zshrc

      HB_CNF_HANDLER="$(brew --prefix)/Homebrew/Library/Taps/homebrew/homebrew-command-not-found/handler.sh"
      if [ -f "$HB_CNF_HANDLER" ]; then
        source "$HB_CNF_HANDLER";
      fi
    EOS
  else
    raise "Unsupported shell type #{shell}"
  end
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

if $stdout.tty?
  help
else
  init
end
