#! /usr/bin/env ruby

#:  * `which-update`
#:     DB updater script for `brew-which-formula`
#:
#:     Usage:
#:
#:     `brew which-update` [`--commit`|`--stats`] <DB file>

require "formula"
require "pathname"
require "set"
require "utils"

# ExecutablesDB represents a DB associating formulae to the binaries they
# provide.
class ExecutablesDB
  attr_accessor :exes
  attr_reader :changes

  # initialize a new DB with the given filename. The file will be used to
  # populate the DB if it exists. It'll be created or overridden when saving the
  # DB.
  # @see #save!
  def initialize(filename)
    @filename = filename
    @exes = {}
    # keeps track of things that changed in the DB between its creation and
    # each {#save!} call. This is used to generate commit messages
    @changes = { :add => Set.new, :remove => Set.new, :update => Set.new }

    if File.file? @filename
      File.new(@filename).each do |line|
        formula, exes_line = line.split(":")
        @exes[formula] ||= []
        @exes[formula].concat exes_line.split(" ") if exes_line
      end
    end
  end

  def formula_names
    @exes.keys
  end

  def root
    @root ||= Pathname.new(@filename).parent
  end

  def changed?
    @changes.any? { |_, v| !v.empty? }
  end

  # update the DB with the installed formulae
  # @see #save!
  def update!
    Formula.each do |f|
      next if f.tap?

      name = f.full_name

      # note: f.installed? is true only if the *latest* version is installed.
      # We thus don't need to worry about updating outdated versions
      if f.installed?
        update_installed_formula f
      elsif missing_formula?(f) && f.bottled?
        update_bottled_formula f
      end

      # renamed formulae
      mv f.oldname, name if !f.oldname.nil? && @exes[f.oldname]

      # aliased formulae
      f.aliases.each do |a|
        mv a, name if @exes[a]
      end
    end

    removed = @exes.keys - Formula.full_names
    removed.each do |name|
      @exes.delete name
      @changes[:remove] << name
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
  end

  private

  def mv(old, new)
    unless @exes[new]
      @exes[new] = @exes[old]
      @changes[:add] << new
    end
    @exes.delete old
    @changes[:remove] << old
    puts "Moving #{old} => #{new}"
  end

  def missing_formula?(formula)
    !@exes.key? formula.full_name
  end

  def update_formula_binaries_from_prefix(formula, prefix = nil)
    prefix ||= formula.prefix

    binaries = Set.new

    Dir["#{prefix}/{bin,sbin}/*"].each do |file|
      binaries << File.basename(file).to_s if File.executable? file
    end

    update_formula_binaries(formula, binaries)
  end

  def update_formula_binaries(formula, binaries)
    name = formula.full_name
    binaries = binaries.to_a.sort

    if missing_formula? formula
      @changes[:add] << name
    elsif @exes[name] != binaries
      @changes[:update] << name
    end

    @exes[name] = binaries
  end

  # update the binaries of {formula}, assuming it's installed
  def update_installed_formula(formula)
    update_formula_binaries_from_prefix formula
  end

  # Add a formula's binaries from its bottle
  def update_bottled_formula(formula)
    formula.bottle.fetch
    path = formula.bottle.resource.cached_download.to_s
    content = Utils.popen_read("tar", "tzvf", path, "*/bin/*")
    binaries = []
    prefix = formula.prefix.relative_path_from(HOMEBREW_CELLAR).to_s
    binpath_re = %r{^#{prefix}/s?bin/}
    content.each_line do |line|
      # skip directories and non-executable files
      # 'l' = symlink, '-' = regular file
      next unless /^[l-]r.x/.match?(line)

      # ignore symlink targets
      line = line.chomp.sub(/\s+->.+$/, "")
      path = line.split(/\s+/).last
      next unless binpath_re.match?(path)

      binaries << Pathname.new(path).basename.to_s
    end

    update_formula_binaries formula, binaries
  end
end

source = ARGV.named.first

unless source
  pwd = Pathname.pwd
  tap_path = Tap.fetch("homebrew", "command-not-found").path
  source = tap_path/"executables.txt"
  unless pwd == tap_path
    relpath = source.relative_path_from(pwd)
    shown_path = (relpath.to_s.length > source.to_s.length) ? source : relpath
    ohai "Using executables list from '#{shown_path}'"
  end
  source.to_s
end

if ARGV.include? "--stats"
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
  exit
end

def english_list(els, verb)
  msg = els.slice(0, 3).join(", ")
  msg << " and #{els.length - 3} more" if msg.length < 40 && els.length > 3
  "#{verb.capitalize} #{msg}"
end

def git_commit_message(changes)
  msg = ""
  [:add, :update, :remove].each do |action|
    names = changes[action]
    next if names.empty?

    msg << english_list(names.to_a.sort, action.to_s)
    break
  end

  msg
end

db = ExecutablesDB.new source
db.update!
db.save!

if ARGV.include?("--commit") && db.changed?
  msg = git_commit_message(db.changes)
  safe_system "git", "-C", db.root.to_s, "commit", "-m", msg, source
end
