#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-

# brew-which-update: DB updater script for `brew-which-formula`
#
# Usage:
#
#   brew which-update [--commit [--push]] <DB file>
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

  # @private
  def reset_changes
    # keeps track of things that changed in the DB between its creation and
    # each {#save!} call. This is used to generate commit messages
    @changes = {:added => Set.new, :removed => Set.new, :updated => Set.new}
  end

  def changed?
    @changes.any? { |_,v| !v.empty? }
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

    unless @exes.has_key?(name)
      @changes[:added] << name
    else
      @changes[:updated] << name unless @exes[name] == binaries
    end

    @exes[name] = binaries
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

      unless f.tap?
        # renamed formulae
        mv f.oldname, name if !f.oldname.nil? && @exes[f.oldname]

        # aliased formulae
        f.aliases.each do |a|
          mv a, name if @exes[a]
        end
      else
        origin = f.name
        if !@exes[name] && @exes[origin]
          mv origin, name
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

    reset_changes
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

  private

  def mv old, new
    unless @exes[new]
      @exes[new] = @exes[old]
      @changes[:added] << new
    end
    @exes.delete old
    @changes[:removed] << old
    puts "Moving #{old} => #{new}"
  end
end


if ARGV.named.empty?
  puts <<-EOS
Usage:

    brew-which-update <DB file>

  EOS
  exit 1
end

if ARGV.include? "--stats"
  source = ARGV.named.first
  opoo "The DB file doesn't exist." unless File.exist? source
  db = ExecutablesDB.new source

  require "official_taps"
  require "cmd/tap"

  formulae = db.exes.keys
  core = Formula.core_names
  taps = OFFICIAL_TAPS.flat_map do |repo|
    tap = Tap.fetch("homebrew", repo)
    Homebrew.install_tap(tap.user, tap.repo) unless tap.installed?
    tap.formula_names
  end

  cmds_count = db.exes.values.reduce(0) { |s, exs| s + exs.size }

  core_percentage = ((formulae & core).size * 100 / core.size.to_f).round(1)
  taps_percentage = ((formulae & taps).size * 100 / taps.size.to_f).round(1)

  puts <<-EOS
#{formulae.size} formulae
#{cmds_count} commands
#{core_percentage}% of core                  (missing: #{(core - formulae) * ", "})
#{taps_percentage}% of taps (excl. boneyard) (missing: #{(taps - formulae) * ", "})
  EOS

  unknown = formulae - Formula.full_names
  puts "\nUnknown formulae: #{unknown * ", "}." if unknown.any?
  exit
end

def english_list(els, state)
  msg = els.slice(0, 3).join(", ")
  msg << "and #{els.length - 3} more" if msg.length < 40 && els.length > 3
  msg << " #{state}"
  msg
end

source = ARGV.named.first
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
    msg << english_list(added, "added")
  elsif !updated.empty?
    msg << english_list(updated, "updated")
  elsif !removed.empty?
    msg << english_list(removed, "removed")
  end

  db.save!

  safe_system "git", "commit", "-m", msg, source
end
