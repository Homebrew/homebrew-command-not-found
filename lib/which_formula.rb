# frozen_string_literal: true

require "formula"

module Homebrew
  module WhichFormula
    LIST_PATH = File.expand_path("#{File.dirname(__FILE__)}/../executables.txt").freeze

    module_function

    def matches(cmd)
      File.readlines(LIST_PATH).map(&:chomp).select { |line| line.include?(cmd) }
    end

    # Test if we have to reject the given formula, i.e. not suggest it.
    def reject_formula?(name)
      f = begin
        Formula[name]
      rescue
        nil
      end
      f.nil? || f.latest_version_installed? || f.requirements.any? { |r| r.required? && !r.satisfied? }
    end

    # Output explanation of how to get 'cmd' by installing one of the providing
    # formulae.
    def explain_formulae_install(cmd, formulae)
      formulae.reject! { |f| reject_formula? f }

      return if formulae.blank?

      if formulae.size == 1
        puts <<~EOS
          The program '#{cmd}' is currently not installed. You can install it by typing:
            brew install #{formulae.first}
        EOS
      else
        puts <<~EOS
          The program '#{cmd}' can be found in the following formulae:
            * #{formulae * "\n  * "}
          Try: brew install <selected formula>
        EOS
      end
    end

    # if 'explain' is false, print all formulae that can be installed to get the
    # given command. If it's true, print them in human-readable form with an help
    # text.
    def which_formula(cmd, explain: false)
      cmd = cmd.downcase

      formulae = (matches cmd).map do |m|
        formula, cmds_text = m.split(":", 2)
        next if formula.nil? || cmds_text.nil?

        cmds = cmds_text.split
        formula if !cmds.nil? && cmds.include?(cmd)
      end.compact

      return if formulae.blank?

      formulae.map! do |formula|
        formula.sub(/\(.*\)$/, "")
      end

      if explain
        explain_formulae_install(cmd, formulae)
      else
        puts formulae * "\n"
      end
    end
  end
end
