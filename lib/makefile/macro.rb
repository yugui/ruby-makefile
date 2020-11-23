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
      expand_internal(macroset, Set.new)
    end

    # Shows some implementation details of #expand
    #
    # Only Makefile::Expression is allowed to call this method.
    # Others should use #expand.
    def expand_internal(macroset, parent_refs)
      raise Makefile::Error.new("Macro #{name} references itself") \
        if parent_refs.include?(name)

      parent_refs << name
      begin
        value.evaluate_internal(macroset, parent_refs)
      ensure
        parent_refs.delete name
      end
    end
  end
end
