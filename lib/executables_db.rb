# frozen_string_literal: true

require "formula"
require "formulary"
require "tap"

module Homebrew
  # ExecutablesDB represents a DB associating formulae to the binaries they
  # provide.
  class ExecutablesDB
    attr_accessor :exes
    attr_reader :changes

    DB_LINE_REGEX = /^(?<name>.*?)(?:\((?<version>.*)\))?:(?<exes_line>.*)?$/

    # initialize a new DB with the given filename. The file will be used to
    # populate the DB if it exists. It'll be created or overridden when saving the
    # DB.
    # @see #save!
    def initialize(filename)
      @filename = filename
      @exes = {}
      # keeps track of things that changed in the DB between its creation and
      # each {#save!} call. This is used to generate commit messages
      @changes = { add: Set.new, remove: Set.new, update: Set.new, version_bump: Set.new }

      return unless File.file? @filename

      File.new(@filename).each do |line|
        matches = line.match DB_LINE_REGEX
        next unless matches

        name = matches[:name]
        version = matches[:version]
        exes_line = matches[:exes_line]

        @exes[name] ||= [version, []]
        @exes[name][1].concat exes_line.split if exes_line.present?
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
    def update!(update_existing: false, install_missing: false, max_downloads: nil, eval_all: false)
      downloads = 0
      disabled_formulae = []

      # Evaluate only the core tap by default.
      taps = eval_all ? Tap.each.to_a : [CoreTap.instance]
      taps.each do |tap|
        tap.formula_files_by_name.each_key do |name|
          f = Formulary.factory("#{tap}/#{name}")

          break if max_downloads.present? && downloads > max_downloads.to_i

          name = f.full_name

          if f.disabled?
            disabled_formulae << name
            next
          end

          update_formula = missing_formula?(f) || (update_existing && outdated_formula?(f))

          # Install unbottled formulae if they should be added/updated
          if !f.bottled? && install_missing && update_formula
            downloads += 1
            ohai "Installing #{f}"
            system HOMEBREW_BREW_FILE, "install", "--formula", f.to_s
          end

          # We don't need to worry about updating outdated versions unless update_existing is true
          if f.latest_version_installed?
            update_installed_formula f
          elsif f.bottled? && update_formula
            downloads += 1
            update_bottled_formula f
          end

          # renamed formulae
          f.oldnames.each do |oldname|
            mv oldname, name if @exes[oldname]
          end

          # aliased formulae
          f.aliases.each do |a|
            mv a, name if @exes[a]
          end
        end
      end

      removed = (@exes.keys - Formula.full_names) | disabled_formulae
      removed.each do |name|
        @exes.delete name
        @changes[:remove] << name
      end
      nil
    end

    # save the DB in the underlying file
    def save!
      ordered_db = @exes.map do |formula, data|
        version, exs = data
        version_string = "(#{version})" if version.present?
        "#{formula}#{version_string}:#{exs.join(" ")}\n"
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

    def outdated_formula?(formula)
      current_version = @exes[formula.full_name][0]
      formula.pkg_version.to_s != current_version
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
      version = formula.pkg_version
      binaries = binaries.to_a.sort

      if missing_formula? formula
        @changes[:add] << name
      elsif @exes[name][1] != binaries
        @changes[:update] << name
      elsif outdated_formula? formula
        @changes[:version_bump] << name
      end

      @exes[name] = [version, binaries]
    end

    # update the binaries of {formula}, assuming it's installed
    def update_installed_formula(formula)
      update_formula_binaries_from_prefix formula
    end

    # Add a formula's binaries from its bottle
    def update_bottled_formula(formula)
      formula.bottle.fetch
      path = formula.bottle.resource.cached_download.to_s
      content = Utils.popen_read("tar", "tzvf", path, "*/bin/*", "*/sbin/*")
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
end
