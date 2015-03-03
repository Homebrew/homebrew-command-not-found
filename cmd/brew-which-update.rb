#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-

# brew-which-update: DB updater script for `brew-which-formula`
#
# Usage:
#
#   brew which-update <DB file>
#

require "formula"
require "pathname"

class ExecutablesDB
  def initialize(filename)
    @filename = filename
    @exes = {}

    if File.file? @filename
      File.new(@filename).each do |line|
        formula, exes_line = line.split(":")
        (@exes[formula] ||= []).concat exes_line.split(" ")
      end
    end
  end

  def update!
    Formula.each do |f|
      tap = f.tap? && f.tap !~ %r(^homebrew/)
      name = tap ? "#{f.tap}/#{f.name}" : f.name

      if File.directory? f.prefix
        @exes[name] ||= []

        Dir["#{f.prefix}/{bin,sbin}/*"].uniq.each do |path|
          next unless File.executable? path
          @exes[name] << Pathname.new(path).basename.to_s
        end

        @exes[name].uniq!
      end

      # this could be removed in the future when all tapped formulae have been
      # migrated to the new prefixed format. Also not sure how this work with
      # conflicting formulae (e.g. "foo" and "someone/sometap/foo").
      if tap
        if !@exes[name]
          if @exes[f.name]
            @exes[name] = @exes[f.name]
            @exes.delete f.name
            puts "Moving #{f.name} => #{name}"
          end
        elsif @exes[name] == @exes[f.name]
          @exes.delete f.name
          puts "Removing #{f.name} (#{name} already present)"
        end
      end
    end
  end

  def save!
    ordered_db = @exes.map do |formula, exs|
      "#{formula}:#{exs.uniq.join(" ")}\n"
    end.sort

    File.open(@filename, "w") do |f|
      ordered_db.each do |line|
        f.write(line)
      end
    end
  end
end

if ARGV.named.empty?
  puts <<-EOS
Usage:

    brew-which-update <DB file>

  EOS
  exit 1
end

db = ExecutablesDB.new ARGV.named.first
db.update!
db.save!
