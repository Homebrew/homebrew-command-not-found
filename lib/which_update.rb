# typed: strict
# frozen_string_literal: true

require_relative "../lib/executables_db"
require "utils/output"

module Homebrew
  module WhichUpdate
    module_function

    sig { returns(String) }
    def default_source
      @default_source ||= T.let(begin
        pwd = Pathname.pwd
        tap_path = Tap.fetch("homebrew", "command-not-found").path
        source = tap_path/"executables.txt"
        if pwd != tap_path
          relpath = source.relative_path_from(pwd)
          shown_path = (relpath.to_s.length > source.to_s.length) ? source : relpath
          Utils::Output.ohai "Using executables list from '#{shown_path}'"
        end
        source.to_s
      end, T.nilable(String))
    end

    sig { params(source: T.nilable(String)).void }
    def stats(source: nil)
      source ||= default_source
      Utils::Output.opoo "The DB file doesn't exist." unless File.exist? source
      db = ExecutablesDB.new source

      formulae = db.formula_names
      core = Formula.core_names

      cmds_count = db.exes.values.reduce(0) { |s, exs| s + exs.binaries.size }

      core_percentage = ((formulae & core).size * 1000 / core.size.to_f).round / 10.0

      missing = (core - formulae).reject { |f| Formula[f].disabled? }
      puts <<~EOS
        #{formulae.size} formulae
        #{cmds_count} commands
        #{core_percentage}%  (missing: #{missing * " "})
      EOS

      unknown = formulae - Formula.full_names
      puts "\nUnknown formulae: #{unknown * ", "}." if unknown.any?
      nil
    end

    sig {
      params(
        source:          T.nilable(String),
        commit:          T::Boolean,
        update_existing: T::Boolean,
        install_missing: T::Boolean,
        max_downloads:   T.nilable(Integer),
        eval_all:        T::Boolean,
        summary_file:    T.nilable(String),
      ).void
    }
    def update_and_save!(source: nil, commit: false, update_existing: false, install_missing: false,
                         max_downloads: nil, eval_all: false, summary_file: nil)
      source ||= default_source
      db = ExecutablesDB.new source
      db.update!(update_existing:, install_missing:,
                 max_downloads:, eval_all:)
      db.save!

      if summary_file
        msg = summary_file_message(db.changes)
        File.open(summary_file, "a") do |file|
          file.puts(msg)
        end
      end

      return if !commit || !db.changed?

      msg = git_commit_message(db.changes)
      safe_system "git", "-C", db.root.to_s, "commit", "-m", msg, source
    end

    sig { params(els: T::Array[String], verb: String).returns(String) }
    def english_list(els, verb)
      msg = +""
      msg << els.slice(0, 3)&.join(", ")
      msg << " and #{els.length - 3} more" if msg.length < 40 && els.length > 3
      "#{verb.capitalize} #{msg}"
    end

    sig { params(changes: ExecutablesDB::Changes).returns(String) }
    def git_commit_message(changes)
      msg = []
      ExecutablesDB::Changes::TYPES.each do |action|
        names = changes.send(action)
        next if names.empty?

        action = "bump version for" if action == :version_bump
        msg << english_list(names.to_a.sort, action.to_s)
        break
      end

      msg.join
    end

    sig { params(changes: ExecutablesDB::Changes).returns(String) }
    def summary_file_message(changes)
      msg = []
      ExecutablesDB::Changes::TYPES.each do |action|
        names = changes.send(action)
        next if names.empty?

        action_heading = action.to_s.split("_").map(&:capitalize).join(" ")
        msg << "### #{action_heading}"
        msg << ""
        names.to_a.sort.each do |name|
          msg << "- [`#{name}`](https://formulae.brew.sh/formula/#{name})"
        end
      end

      msg << "No changes" if msg.empty?

      <<~MESSAGE
        ## Database Update Summary

        #{msg.join("\n")}
      MESSAGE
    end
  end
end
