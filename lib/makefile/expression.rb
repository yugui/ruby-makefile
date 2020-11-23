require 'set'

module Makefile
  MACRO_REF_PATTERN = %r!
    \$ (?:
      \( ([^)]+) \) |
       { ([^}]+) }  |
         ([^({])
    )
  !x

  # An expression which can contain macro reference
  class Expression
    def initialize(raw_text)
      @raw_text = raw_text
    end
    attr_reader :raw_text

    def evaluate(target=nil, macroset)
      evaluate_internal(target, macroset, Set.new)
    end

    # Shows some implementation details of #evaluate
    #
    # Only Makefile::Macro is allowed to call this method.
    # Others should use #evaluate
    def evaluate_internal(target, macroset, parent_refs)
      raw_text.gsub(MACRO_REF_PATTERN) do
        if $3
          name, type = $3, :single
        else
          name, type = $1 || $2, :quoted
        end

        macro = macroset[name]
        if macro&.match?(type)
          macro&.expand_internal(target, macroset, parent_refs)
        end
      end
    end
  end
end
