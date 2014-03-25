module Makefile; end

class Makefile::SuffixRule
  def initialize(source, target)
    @source = source
    @target = target
    @commands = []
  end

  attr_reader :source, :target, :commands

  def add_command(command)
    @commands << command
  end
end
