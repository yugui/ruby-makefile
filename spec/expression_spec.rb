require_relative "spec_helper"
require 'makefile'

describe Makefile::Expression do
  describe '#evaluate' do
    it 'returns literal expression as is' do
      expr = Makefile::Expression.new('abcde fghij')
      macroset = double('macroset')
      result = expr.evaluate(macroset)

      expect(result).to eq('abcde fghij')
    end

    it 'expands single letter macros' do
      expr = Makefile::Expression.new('A$BCDE $F $G')
      result = expr.evaluate(
        'B' => Makefile::Macro.new('B', 'b'),
        'F' => Makefile::Macro.new('F', 'f'),
        'G' => Makefile::Macro.new('G', 'g'),
      )

      expect(result).to eq('AbCDE f g')
    end

    it 'expands parenthesized macros' do
      expr = Makefile::Expression.new('A$(BCD)E $(FG)')
      result = expr.evaluate(
        'B' => Makefile::Macro.new('B', 'b'),
        'BCD' => Makefile::Macro.new('BCD', '123'),
        'FG' => Makefile::Macro.new('FG', '45'),
      )

      expect(result).to eq('A123E 45')
    end

    it 'expands braced macros' do
      expr = Makefile::Expression.new('A${BCD}E ${FG}')
      result = expr.evaluate(
        'B' => Makefile::Macro.new('B', 'b'),
        'BCD' => Makefile::Macro.new('BCD', '123'),
        'FG' => Makefile::Macro.new('FG', '45'),
      )

      expect(result).to eq('A123E 45')
    end

    it 'expands undefined macros into blank' do
      expr = Makefile::Expression.new('A$BCD$(EF)G${HI}')
      result = expr.evaluate({})

      expect(result).to eq('ACDG')
    end

    it 'expands $$ to $' do
      expr = Makefile::Expression.new('$${A}')
      result = expr.evaluate(
        'A' => 'a',
      )

      expect(result).to eq('${A}')
    end

    it 'expands only once' do
    end
  end
end
