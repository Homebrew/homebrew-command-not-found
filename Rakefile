require "open3"
require "test/unit/assertions"

include Test::Unit::Assertions # rubocop:disable Style/MixinUsage

task :test => ["test:bash", "test:fish", "test:zsh"]

namespace :test do
  [:bash, :zsh].each do |sh|
    task sh do
      puts "Testing with #{sh}"
      command = "eval \"$(brew command-not-found-init)\"; when"
      # -e: exit on first error
      # -x: trace
      # -c: execute the command
      output, status = Open3.capture2e(sh.to_s, "-ex", "-c", command)
      puts
      puts output
      puts
      assert_equal 127, status.exitstatus
      assert_match(/brew install when/, output)
    end
  end

  task :fish do
    puts "Testing with fish"
    # use `emit fish_prompt` to simulate interactive shell
    command = ". (brew command-not-found-init); emit fish_prompt; when"
    output, status = Open3.capture2e("fish", "-c", command)
    puts
    puts output
    puts
    assert_equal 127, status.exitstatus
    assert_match(/brew install when/, output)
  end
end
