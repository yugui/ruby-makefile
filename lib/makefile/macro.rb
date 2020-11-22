require 'makefile/expression'

module Makefile
  class Macro
    def initialize(name, raw_value)
      @name = name
      @raw_value = raw_value
      @value = Expression.new(raw_value)
    end
    attr_reader :name, :raw_value, :value

    def expand(macroset)
      value.evaluate(macroset)
    end
  end
end
