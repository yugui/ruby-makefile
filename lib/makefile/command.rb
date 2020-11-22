require 'shellwords'

module Makefile
  class Command
    def initialize(raw_cmd, rule)
      @rule = rule
      @raw_cmd = raw_cmd
      @cmd = Expression.new(raw_cmd)
    end

    attr_reader :rule, :raw_cmd, :cmd

    def ==(rhs)
      self.rule == rhs.rule and self.raw_cmd == rhs.raw_cmd
    end

    def argv(macroset)
      Shellwords.split(cmd.evaluate(macroset))
    end
  end
end
