#!/usr/bin/env ruby

def shell
  if s = ARGV.value("shell")
    return s.to_sym
  end

  parent_shell = `ps c -p #{Process.ppid} -o 'ucomm='` rescue ENV["SHELL"]
  parent_shell = ENV["SHELL"] if parent_shell.empty?

  case parent_shell.rpartition("/").last
  when /^(ba)?sh/ then :bash
  when /^fish/ then :fish
  when /^zsh/ then :zsh
  else :bash
  end
end

def help
  case shell
  when :bash
    puts <<-EOS.undent
      # To enable homebrew-command-not-found
      # Adding the following lines to ~/.bashrc

      if brew command command-not-found-init > /dev/null; then
        eval "$(brew command-not-found-init)";
      fi
    EOS
  when :fish
    puts <<-EOS.undent
      # To enable homebrew-command-not-found
      # Adding the following line to ~/.config/fish/config.fish

      brew command command-not-found-init > /dev/null; and . (brew command-not-found-init)
    EOS
  when :zsh
    puts <<-EOS.undent
      # To enable homebrew-command-not-found
      # Adding the following lines to ~/.zshrc

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
    puts File.read(File.expand_path "#{File.dirname(__FILE__)}/../handler.sh")
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

