require_relative "spec_helper"
require 'makefile'

describe Makefile::Expression do
  describe '#evaluate' do
    it 'returns literal expression as is' do
      expr = Makefile::Expression.new('abcde fghij')
      target = double('target')
      macroset = double('macroset')

      result = expr.evaluate(target, macroset)

      expect(result).to eq('abcde fghij')
    end

    it 'expands single letter macros' do
      expr = Makefile::Expression.new('A$BCDE $F $G')
      result = expr.evaluate(
        double('target'),
        'B' => Makefile::Macro.new('B', 'b'),
        'F' => Makefile::Macro.new('F', 'f'),
        'G' => Makefile::Macro.new('G', 'g'),
      )

      expect(result).to eq('AbCDE f g')
    end

    it 'expands parenthesized macros' do
      expr = Makefile::Expression.new('A$(BCD)E $(FG)')
      result = expr.evaluate(
        double('target'),
        'B' => Makefile::Macro.new('B', 'b'),
        'BCD' => Makefile::Macro.new('BCD', '123'),
        'FG' => Makefile::Macro.new('FG', '45'),
      )

      expect(result).to eq('A123E 45')
    end

    it 'expands braced macros' do
      expr = Makefile::Expression.new('A${BCD}E ${FG}')
      result = expr.evaluate(
        double('target'),
        'B' => Makefile::Macro.new('B', 'b'),
        'BCD' => Makefile::Macro.new('BCD', '123'),
        'FG' => Makefile::Macro.new('FG', '45'),
      )

      expect(result).to eq('A123E 45')
    end

    it 'expands undefined macros into blank' do
      expr = Makefile::Expression.new('A$BCD$(EF)G${HI}')
      result = expr.evaluate(double('target'), {})

      expect(result).to eq('ACDG')
    end

    it 'raises an exception on self-recursion' do
      expr = Makefile::Expression.new('$A')
      expect {
        expr.evaluate(
          double('target'),
          'A' => Makefile::Macro.new('A', '_${A}'),
        )
      }.to raise_error(Makefile::Error)
    end

    it 'raises an exception on mutual recursion' do
      expr = Makefile::Expression.new('$A')
      expect {
        expr.evaluate(
          double('target'),
          'A' => Makefile::Macro.new('A', '_${B}'),
          'B' => Makefile::Macro.new('B', '-${A}'),
        )
      }.to raise_error(Makefile::Error)
    end

    it 'expands $$ to $' do
      expr = Makefile::Expression.new('$${A}')
      result = expr.evaluate(
        double('target'),
        'A' => 'a',
        '$' => Makefile::Macro.new('$', '$', allow_quoted: false),
      )

      expect(result).to eq('${A}')
    end

    %w[ $($) ${$} ].each do |ref|
      it "does not expand #{ref} with the default rule" do
        expr = Makefile::Expression.new(ref)
        result = expr.evaluate(
          double('target'),
          '$' => Makefile::Macro.new('$', '$', allow_quoted: false),
        )

        expect(result).to eq("")
      end
    end

    it 'expands only once' do
      expr = Makefile::Expression.new('$T')
      result = expr.evaluate(
        double('target'),
        'M' => Makefile::Macro.new('M', '$$'),
        'N' => Makefile::Macro.new('N', '(S)'),
        'S' => Makefile::Macro.new('S', '1'),
        'T' => Makefile::Macro.new('T', '$(M)$(N)'),
        '$' => Makefile::Macro.new('$', '$', allow_quoted: false),
      )

      expect(result).to eq('$(S)')
    end

    it 'allows hook variables' do
      expr = Makefile::Expression.new('$A')
      target = double('target')
      called = false
      macroset = {
        'A' => Makefile::Macro.new('A') do |t, m|
          called = true
          expect(t).to equal(target)
          expect(m).to eq(macroset)

          'abcde'
        end
      }
      result = expr.evaluate(target, macroset)

      expect(called).to be_truthy
      expect(result).to eq('abcde')
    end
  end
end
