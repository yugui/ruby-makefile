require 'shellwords'

module Makefile
  class Command
    def initialize(raw_cmd)
      @raw_cmd = raw_cmd
      @cmd = Expression.new(raw_cmd)
    end

    attr_reader :raw_cmd, :cmd

    def ==(rhs)
      self.raw_cmd == rhs.raw_cmd
    end

    def argv(target, macroset)
      args = cmd.evaluate(target, macroset).sub(/\A@/, '')
      Shellwords.split(args)
    end
  end
end
