require_relative "spec_helper"
require 'makefile'

describe Makefile::Command do
  describe '#argv' do
    it "spilts shell tokens" do
      cmd = Makefile::Command.new("ls -l spec/command_spec.rb")
      target = double('target')
      argv = cmd.argv(target, {})

      expect(argv).to eq(%w[ ls -l spec/command_spec.rb ])
    end

    it "evaluates macro before split " do
      cmd = Makefile::Command.new("${A}$(B) C$(D)")
      target = double('target')
      argv = cmd.argv(
        target,
        'A' => Makefile::Macro.new('A', 'a '),
        'B' => Makefile::Macro.new('B', 'b '),
        'D' => Makefile::Macro.new('D', 'd '),
      )

      expect(argv).to eq(%w[ a b Cd ])
    end

    it "propagates target to macro expansion" do
      cmd = Makefile::Command.new("${A}")
      target = double('target')
      expect(cmd.cmd).to receive(:evaluate).with(target, anything).and_call_original

      cmd.argv(
        target,
        'A' => Makefile::Macro.new('A') { 'a' },
      )
    end
  end
end
