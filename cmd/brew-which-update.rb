#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-

# brew-which-update: DB updater script for `brew-which-formula`
#
# Usage:
#
#   brew which-update <DB file>
#

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

  Dir["#{HOMEBREW_CELLAR}/*"].each do |d|
    formula = d.split("/")[-1].strip.downcase
    base[formula] ||= []

    Dir["#{d}/*/bin/*"].uniq do |path|
      next unless File.executable? path
      base[formula] << path.split("/")[-1].strip
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
