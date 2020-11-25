module Makefile
  class Target
    def initialize(macroset, name, raw_deps: nil, commands: [])
      @macroset = macroset
      @name = name
      @raw_deps, @deps = [], []
      add_dependency(raw_deps) if raw_deps
      @commands = commands
    end

    attr_reader :name, :raw_deps, :commands

    def deps
      @deps.map {|expr| expr.evaluate(@macroset).strip.split(/\s+/) }.flatten
    end

    def add_dependency(raw_deps)
      @raw_deps << raw_deps
      @deps << Expression.new(@macroset, raw_deps)
    end

    def add_command(command)
      @commands << command
    end
  end
end
