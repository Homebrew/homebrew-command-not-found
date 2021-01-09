# frozen_string_literal: true

require_relative "../lib/executables_db"

module Homebrew
  module WhichUpdate
    module_function

    def default_source
      @default_source ||= begin
        pwd = Pathname.pwd
        tap_path = Tap.fetch("homebrew", "command-not-found").path
        source = tap_path/"executables.txt"
        if pwd != tap_path
          relpath = source.relative_path_from(pwd)
          shown_path = (relpath.to_s.length > source.to_s.length) ? source : relpath
          ohai "Using executables list from '#{shown_path}'"
        end
        source.to_s
      end
    end

    def stats(source: nil)
      source ||= default_source
      opoo "The DB file doesn't exist." unless File.exist? source
      db = ExecutablesDB.new source

      formulae = db.formula_names
      core = Formula.core_names

      cmds_count = db.exes.values.reduce(0) { |s, exs| s + exs.size }

      core_percentage = ((formulae & core).size * 1000 / core.size.to_f).round / 10.0

      puts <<~EOS
        #{formulae.size} formulae
        #{cmds_count} commands
        #{core_percentage}%  (missing: #{(core - formulae) * " "})
      EOS

      unknown = formulae - Formula.full_names
      puts "\nUnknown formulae: #{unknown * ", "}." if unknown.any?
      nil
    end

    def update_and_save!(source: nil, commit: false)
      source ||= default_source
      db = ExecutablesDB.new source
      db.update!
      db.save!
      return unless commit && db.changed?

      msg = git_commit_message(db.changes)
      safe_system "git", "-C", db.root.to_s, "commit", "-m", msg, source
    end

    def english_list(els, verb)
      msg = els.slice(0, 3).join(", ")
      msg << " and #{els.length - 3} more" if msg.length < 40 && els.length > 3
      "#{verb.capitalize} #{msg}"
    end

    def git_commit_message(changes)
      msg = []
      [:add, :update, :remove].each do |action|
        names = changes[action]
        next if names.empty?

        msg << english_list(names.to_a.sort, action.to_s)
        break
      end

      msg.join
    end
  end
end
