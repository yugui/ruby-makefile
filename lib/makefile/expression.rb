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

    def evaluate(macroset)
      raw_text.gsub(MACRO_REF_PATTERN) do
        name = $1 || $2 || $3
        macroset[name]&.expand(macroset)
      end
    end
  end
end
