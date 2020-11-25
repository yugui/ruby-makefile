module Makefile; end

class Makefile::SuffixRule
  def initialize(macroset, source, target)
    @macroset = macroset
    @source = source
    @target = target
    @commands = []
  end

  attr_reader :source, :target, :commands

  def add_command(command)
    @commands << command
  end

  def resolve_commands(target_name)
    target = resolve(target_name)
    target.commands.map do |cmd|
      cmd.resolve(target)
    end
  end

  private
  def resolve(target_name)
    base = File.basename(name, target)
    Target.new(@macroset, target_name, "#{base}#{source}", @commands)
  end
end
