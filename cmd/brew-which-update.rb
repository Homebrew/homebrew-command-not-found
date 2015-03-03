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

def read_db(filename)
  exes = {}

  File.new(filename).each do |line|
    formula, exes_line = line.split(":")
    (exes[formula] ||= []).concat exes_line.split(" ")
  end

  exes
end

def make_db(base=nil)
  base = {} if base.nil?

  Formula.each do |f|
    tap = f.tap? && f.tap !~ %r(^homebrew/)
    name = tap ? "#{f.tap}/#{f.name}" : f.name

    if File.directory? f.prefix
      base[name] ||= []

      Dir["#{f.prefix}/{bin,sbin}/*"].uniq.each do |path|
        next unless File.executable? path
        base[name] << Pathname.new(path).basename.to_s
      end

      base[name].uniq!
    end

    # this could be removed in the future when all tapped formulae have been
    # migrated to the new prefixed format. Also not sure how this work with
    # conflicting formulae (e.g. "foo" and "someone/sometap/foo").
    if tap
      if !base[name]
        if base[f.name]
          base[name] = base[f.name]
          base.delete f.name
          puts "Moving #{f.name} => #{name}"
        end
      elsif base[name] == base[f.name]
        base.delete f.name
        puts "Removing #{f.name} (#{name} already present)"
      end
    end
  end

  base
end

def save_db(db, filename)
  ordered_db = db.map do |formula, exes|
    "#{formula}:#{exes.uniq.join(" ")}\n"
  end.sort

  File.open(filename, "w") do |f|
    ordered_db.each do |line|
      f.write(line)
    end
  end
end

db_filename = ARGV.named.first
if db_filename.nil?
  puts <<-EOS
Usage:

    brew-which-update <DB file>

  EOS
  exit 1
end

# 1. get the existing DB
orig = File.file?(db_filename) ? read_db(db_filename) : {}

# 2. update it
db = make_db orig

# 3. save it
save_db(db, db_filename)
