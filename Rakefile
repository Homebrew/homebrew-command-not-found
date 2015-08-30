require "open3"
require "test/unit/assertions"
include Test::Unit::Assertions

task :test => ["test:bash", "test:fish", "test:zsh"]

namespace :test do
  [:bash, :zsh].each do |sh|
    task sh do
      puts "Testing with #{sh}"
      command = "eval \"$(brew command-not-found-init)\"; when"
      # -e: exit on first error
      # -x: trace
      # -c: execute the command
      output, status = Open3.capture2e("#{sh}", "-ex", "-c", command)
      puts output
      assert_equal status.exitstatus, 127
      assert_match /brew install when/, output
    end
  end

  task :fish do
    puts "Testing with fish"
    # use `emit fish_prompt` to simulate interactive shell
    command = ". (brew command-not-found-init); emit fish_prompt; when"
    output, status = Open3.capture2e("fish", "--debug-level=3", "-c", command)
    puts output
    assert_equal status.exitstatus, 127
    assert_match /brew install when/, output
  end
end
