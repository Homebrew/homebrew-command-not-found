#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-

# brew-which-update: DB updater script for `brew-which-formula`
#
# Usage:
#
#   brew which-update [--commit|--stats] [<DB file>]
#

require "formula"
require "pathname"
require "set"

# ExecutablesDB represents a DB associating formulae to the binaries they
# provide.
class ExecutablesDB
  attr_accessor :exes
  attr_reader :changes

  # initialize a new DB with the given filename. The file will be used to
  # populate the DB if it exists. It'll be created or overrided when saving the
  # DB.
  # @see #save!
  def initialize(filename)
    @filename = filename
    @exes = {}

    reset_changes

    if File.file? @filename
      File.new(@filename).each do |line|
        formula, exes_line = line.split(":")
        (@exes[formula] ||= []).concat exes_line.split(" ")
      end
    end
  end

  def root
    @root ||= Pathname.new(@filename).parent
  end

  # @private
  def reset_changes
    # keeps track of things that changed in the DB between its creation and
    # each {#save!} call. This is used to generate commit messages
    @changes = { :added => Set.new, :removed => Set.new, :updated => Set.new }
  end

  def changed?
    @changes.any? { |_, v| !v.empty? }
  end

  # update the binaries of {name} given the prefix path {path}.
  # @private
  def update_from(name, path)
    binaries = Set.new
    Dir["#{path}/{bin,sbin}/*"].each do |f|
      next unless File.executable? f
      binaries << Pathname.new(f).basename.to_s
    end

    binaries = binaries.to_a.sort

    if @exes.key?(name)
      @changes[:updated] << name unless @exes[name] == binaries
    else
      @changes[:added] << name
    end

    @exes[name] = binaries
  end

  # update the DB with the installed formulae
  # @see #save!
  def update!
    Formula.each do |f|
      next if f.tap? && !f.tap.official?
      name = f.full_name

      # note: f.installed? is true only if the *latest* version is installed.
      # We thus don't need to worry about updating outdated versions
      update_from name, f.prefix if f.installed?

      if f.tap?
        origin = f.name
        if !@exes[name] && @exes[origin]
          mv origin, name
        end
      else
        # renamed formulae
        mv f.oldname, name if !f.oldname.nil? && @exes[f.oldname]

        # aliased formulae
        f.aliases.each do |a|
          mv a, name if @exes[a]
        end
      end
    end

    removed = @exes.keys - Formula.full_names
    removed.each do |name|
      @exes.delete name
      @changes[:removed] << name
    end
    nil
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

    reset_changes
  end

  # Add a formulae binaries from its bottle. It'll abort if the formula doesn't
  # have a bottle.
  def add_from_bottle(name)
    f = Formula[name]
    abort "Formula #{name} has no bottle" unless f.bottled?

    f.bottle.fetch
    f.bottle.resource.stage do
      update_from f.full_name, Dir["*"].first
    end
  end

  private

  def mv(old, new)
    unless @exes[new]
      @exes[new] = @exes[old]
      @changes[:added] << new
    end
    @exes.delete old
    @changes[:removed] << old
    puts "Moving #{old} => #{new}"
  end
end

source = ARGV.named.first

unless source
  pwd = Pathname.pwd
  tap_path = Tap.fetch("homebrew", "command-not-found").path
  source = tap_path/"executables.txt"
  unless pwd == tap_path
    relpath = source.relative_path_from(pwd)
    shown_path = relpath.to_s.length > source.to_s.length ? source : relpath
    ohai "Using executables list from '#{shown_path}'"
  end
  source.to_s
end

if ARGV.include? "--stats"
  opoo "The DB file doesn't exist." unless File.exist? source
  db = ExecutablesDB.new source

  require "official_taps"

  formulae = db.exes.keys
  core = Formula.core_names
  taps = OFFICIAL_TAPS.flat_map do |repo|
    tap = Tap.fetch("homebrew", repo)
    tap.install unless tap.installed?
    tap.formula_names
  end

  cmds_count = db.exes.values.reduce(0) { |s, exs| s + exs.size }

  core_percentage = ((formulae & core).size * 1000 / core.size.to_f).round / 10.0
  taps_percentage = ((formulae & taps).size * 1000 / taps.size.to_f).round / 10.0

  puts <<-EOS
#{formulae.size} formulae
#{cmds_count} commands
#{core_percentage}% of core          (missing: #{(core - formulae) * ", "})
#{taps_percentage}% of official taps (missing: #{(taps - formulae) * ", "})
  EOS

  unknown = formulae - Formula.full_names
  puts "\nUnknown formulae: #{unknown * ", "}." if unknown.any?
  exit
end

def english_list(els, verb)
  msg = els.slice(0, 3).join(", ")
  msg << " and #{els.length - 3} more" if msg.length < 40 && els.length > 3
  "#{verb.capitalize} #{msg}"
end

db = ExecutablesDB.new source
db.update!
changes = db.changes
changed = db.changed?
db.save!

if ARGV.include?("--commit") && changed
  msg = ""

  added = changes[:added].to_a.sort
  updated = changes[:updated].to_a.sort
  removed = changes[:removed].to_a.sort

  # we don't try to report everything, only the most common stuff
  if !added.empty?
    msg << english_list(added, "add")
  elsif !updated.empty?
    msg << english_list(updated, "update")
  elsif !removed.empty?
    msg << english_list(removed, "remove")
  end

  db.save!

  safe_system "git", "-C", db.root.to_s, "commit", "-m", msg, source
end
