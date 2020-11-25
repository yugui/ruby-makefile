require_relative "spec_helper"
require 'makefile'

describe Makefile::Command do
  describe '#argv' do
    it "spilts shell tokens" do
      cmd = Makefile::Command.new(
        double('macroset'),
        "ls -l spec/command_spec.rb"
      )
      target = double('target')
      argv = cmd.argv(target)

      expect(argv).to eq(%w[ ls -l spec/command_spec.rb ])
    end

    it "evaluates macro before split " do
      cmd = Makefile::Command.new(
        macroset(
          'A' => 'a ',
          'B' => 'b ',
          'D' => 'd ',
        ),
        "${A}$(B) C$(D)"
      )
      target = double('target')
      argv = cmd.argv(target)

      expect(argv).to eq(%w[ a b Cd ])
    end

    it "propagates target to macro expansion" do
      cmd = Makefile::Command.new(
        macroset('A' => 'a'),
        "${A}"
      )
      target = double('target')
      expect(cmd.cmd).to receive(:evaluate).with(target).and_call_original

      cmd.argv(target)
    end

    it "ignores silence marker" do
      cmd = Makefile::Command.new(
        macroset('Q' => '@'),
        "$(Q)echo 1",
      )
      argv = cmd.argv(double('target'))

      expect(argv).to eq(%w[ echo 1 ])
    end
  end
end
