require 'shellwords'

module Makefile
  class Command
    def initialize(macroset, raw_cmd)
      @raw_cmd = raw_cmd
      @cmd = Expression.new(macroset, raw_cmd)
    end

    attr_reader :raw_cmd, :cmd

    def ==(rhs)
      self.raw_cmd == rhs.raw_cmd
    end

    def argv(target)
      args = cmd.evaluate(target).sub(/\A@/, '')
      Shellwords.split(args)
    end
  end
end
