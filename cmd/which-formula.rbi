# typed: strict

class Homebrew::Cmd::WhichFormulaCmd
  sig { returns(Homebrew::Cmd::WhichFormulaCmd::Args) }
  def args; end
end

class Homebrew::Cmd::WhichFormulaCmd::Args < Homebrew::CLI::Args
  sig { returns(T::Boolean) }
  def explain?; end

  sig { returns(T::Boolean) }
  def skip_update?; end
end
