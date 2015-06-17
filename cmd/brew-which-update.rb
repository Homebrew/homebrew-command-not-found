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
  attr_accessor :exes

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

  def update_from(name, path)
    @exes[name] = []
    Dir["#{path}/{bin,sbin}/*"].uniq.each do |f|
      next unless File.executable? f
      @exes[name] << Pathname.new(f).basename.to_s
    end
    @exes[name].uniq!
  end

  def update!
    Formula.each do |f|
      tap = f.tap? #&& f.tap !~ %r(^homebrew/)
      name = tap ? "#{f.tap}/#{f.name}" : f.name

      # TODO check that the formula is not outdated
      update_from name, f.prefix if f.installed?

      if tap
        origin = f.name
        if !@exes[name] && @exes[origin]
          @exes[name] = @exes[origin]
          @exes.delete origin
          puts "Moving #{origin} => #{name}"
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

  def add_from_bottle name
    f = Formula[name]
    abort "Formula #{name} has no bottle" unless f.bottled?

    f.bottle.fetch
    f.bottle.resource.stage do
      update_from f.full_name, Dir["*"].first
    end
  end
end

# This variable should never be defined, I put it in my ~/.irbrc so requiring
# this file in `irb` doesn't run this code block
unless $BFN_IRB
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
end
