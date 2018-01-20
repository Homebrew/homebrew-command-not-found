#!/usr/bin/env ruby

def shell
  Utils::Shell.parent || Utils::Shell.preferred
end

def help
  case shell
  when :bash
    puts <<~EOS
      # To enable homebrew-command-not-found
      # Add the following lines to ~/.bashrc

      if brew command command-not-found-init > /dev/null; then
        eval "$(brew command-not-found-init)";
      fi
    EOS
  when :fish
    puts <<~EOS
      # To enable homebrew-command-not-found
      # Add the following line to ~/.config/fish/config.fish

      brew command command-not-found-init > /dev/null; and . (brew command-not-found-init)
    EOS
  when :zsh
    puts <<~EOS
      # To enable homebrew-command-not-found
      # Add the following lines to ~/.zshrc

      if brew command command-not-found-init > /dev/null; then
        eval "$(brew command-not-found-init)";
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
