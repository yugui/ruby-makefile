require_relative "spec_helper"
require 'makefile'

describe Makefile::Command do
  describe '#argv' do
    it "spilts shell tokens" do
      rule = double('rule')
      cmd = Makefile::Command.new("ls -l spec/command_spec.rb", rule)
      argv = cmd.argv({})

      expect(argv).to eq(%w[ ls -l spec/command_spec.rb ])
    end

    it "evaluates macro before split " do
      rule = double('rule')
      cmd = Makefile::Command.new("${A}$(B) C$(D)", rule)
      argv = cmd.argv(
        'A' => Makefile::Macro.new('A', 'a '),
        'B' => Makefile::Macro.new('B', 'b '),
        'D' => Makefile::Macro.new('D', 'd '),
      )

      expect(argv).to eq(%w[ a b Cd ])
    end
  end
end
