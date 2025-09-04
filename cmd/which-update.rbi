# typed: strict

class Homebrew::Cmd::WhichUpdateCmd
  sig { returns(Homebrew::Cmd::WhichUpdateCmd::Args) }
  def args; end
end

class Homebrew::Cmd::WhichUpdateCmd::Args < Homebrew::CLI::Args
  sig { returns(T::Boolean) }
  def stats?; end

  sig { returns(T::Boolean) }
  def commit?; end

  sig { returns(T::Boolean) }
  def update_existing?; end

  sig { returns(T::Boolean) }
  def install_missing?; end

  sig { returns(T::Boolean) }
  def eval_all?; end

  sig { returns(T.nilable(Integer)) }
  def max_downloads; end

  sig { returns(T.nilable(String)) }
  def summary_file; end
end
