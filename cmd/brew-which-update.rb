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
require "set"

# ExecutablesDB represents a DB associating formulae to the binaries they
# provide.
class ExecutablesDB
  attr_accessor :exes

  # initialize a new DB with the given filename. The file will be used to
  # populate the DB if it exists. It'll be created or overrided when saving the
  # DB.
  # @see #save!
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

  # update the binaries of {name} given the prefix path {path}.
  # @private
  def update_from(name, path)
    binaries = Set.new
    Dir["#{path}/{bin,sbin}/*"].uniq.each do |f|
      next unless File.executable? f
      binaries << Pathname.new(f).basename.to_s
    end
    @exes[name] = binaries.to_a.sort
  end

  # update the DB with the installed formulae
  # @see #save!
  def update!
    Formula.each do |f|
      next if f.tap? && !f.tap.include?("omebrew/")
      name = f.full_name

      # note: f.installed? is true only if the *latest* version is installed.
      # We thus don't need to worry about updating outdated versions
      update_from name, f.prefix if f.installed?

      if f.tap?
        origin = f.name
        if !@exes[name] && @exes[origin]
          @exes[name] = @exes[origin]
          @exes.delete origin
          puts "Moving #{origin} => #{name}"
        end
      end
    end
  end

  # save the DB in the underlying file
  def save!
    ordered_db = @exes.map do |formula, exs|
      "#{formula}:#{exs.join(" ")}\n"
    end.sort

    File.open(@filename, "w") do |f|
      ordered_db.each do |line|
        f.write(line)
      end
    end
  end

  # Add a formulae binaries from its bottle. It'll abort if the formula doesn't
  # have a bottle.
  def add_from_bottle name
    f = Formula[name]
    abort "Formula #{name} has no bottle" unless f.bottled?

    f.bottle.fetch
    f.bottle.resource.stage do
      update_from f.full_name, Dir["*"].first
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
