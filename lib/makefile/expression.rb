require 'set'

module Makefile
  MACRO_REF_PATTERN = %r!
    \$ (?:
      \(
        (?<paren> [^:)]+ ) (?: :(?<paren_subst>[^=]+) = (?<paren_substval>[^)]*) )?
      \) |
      {
        (?<brace> [^:}]+ ) (?: :(?<brace_subst>[^=]+) = (?<brace_substval>[^}]*) )?
      }  |
        (?<single> [^({] )
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
        match = $~
        case
        when match[:single]
          type, name = :single, $~[:single]
        when match[:paren]
          type = :quoted
          name = match[:paren]
          substpat, substexpr = match[:paren_subst], match[:paren_substval]
        when match[:brace]
          type = :quoted
          name = match[:brace]
          substpat, substexpr = match[:brace_subst], match[:brace_substval]
        else
          raise 'never reach'
        end

        macro = macroset[name]
        if macro&.match?(type)
          expanded = macro.expand_internal(target, macroset, parent_refs)
          next expanded unless substpat

          replacement = Expression.new(substexpr).
            evaluate_internal(target, macroset, parent_refs)
          expanded.gsub(/#{Regexp.escape substpat}(?=\s|$)/, replacement)
        end
      end
    end
  end
end
