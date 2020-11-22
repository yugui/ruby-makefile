module Makefile
  class Target
    def initialize(name, raw_deps: nil, commands: [])
      @name = name
      if raw_deps
        @raw_deps = [raw_deps]
        @deps = [Expression.new(raw_deps)]
      else
        @raw_deps, @deps = [], []
      end
      @commands = commands
    end

    attr_reader :name, :raw_deps, :commands

    def deps(macroset)
      @deps.map {|expr| expr.evaluate(macroset).split(/\s+/) }.flatten
    end

    def add_dependency(raw_deps)
      @raw_deps << raw_deps
      @deps << Expression.new(raw_deps)
    end

    def add_command(command)
      @commands << command
    end
  end
end
