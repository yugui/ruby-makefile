require 'rspec'

def macroset(macros)
  {}.tap do |macroset|
    macroset['$'] = Makefile::Macro.new(macroset, '$', '$', allow_quoted: false)
    macros.each do |name, raw_expr|
      macroset[name] = Makefile::Macro.new(macroset, name, raw_expr)
    end
  end
end
