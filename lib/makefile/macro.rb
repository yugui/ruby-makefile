require 'makefile/expression'

module Makefile
  class Macro
    def initialize(name, raw_value = nil, allow_single: true, allow_quoted: true, &block)
      raise ArgumentError, 'either raw_value or block must be given' unless \
        raw_value or block

      @name = name
      @raw_value = raw_value
      @value = Expression.new(raw_value) if raw_value
      @allow_single = allow_single
      @allow_quoted = allow_quoted
      @block = block
    end
    attr_reader :name, :raw_value, :value

    def match?(type)
      case type
      when :single
        return @allow_single
      when :quoted
        return @allow_quoted
      else
        raise ArgumentError, 'must be :single or :quoted'
      end
    end

    # Shows some implementation details of #expand
    #
    # Only Makefile::Expression is allowed to call this method.
    def expand_internal(target, macroset, parent_refs)
      raise Makefile::Error, "Macro #{name} references itself" \
        if parent_refs.include?(name)

      parent_refs << name
      begin
        expr = value || Expression.new(@block.call(target, macroset))
        expr.evaluate_internal(target, macroset, parent_refs)
      ensure
        parent_refs.delete name
      end
    end
  end
end
