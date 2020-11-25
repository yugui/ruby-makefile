require_relative "spec_helper"
require 'makefile'

describe Makefile::Expression do
  describe '#evaluate' do
    it 'returns literal expression as is' do
      macroset = double('macroset')
      expr = Makefile::Expression.new(macroset, 'abcde fghij')
      target = double('target')

      result = expr.evaluate(target)

      expect(result).to eq('abcde fghij')
    end

    it 'expands single letter macros' do
      expr = Makefile::Expression.new(
        macroset(
          'B' => 'b',
          'F' => 'f',
          'G' => 'g',
        ),
        'A$BCDE $F $G'
      )
      result = expr.evaluate(double('target'))

      expect(result).to eq('AbCDE f g')
    end

    it 'expands parenthesized macros' do
      expr = Makefile::Expression.new(
        macroset(
          'B' => 'b',
          'BCD' => '123',
          'FG' => '45',
        ),
        'A$(BCD)E $(FG)'
      )
      result = expr.evaluate(double('target'))

      expect(result).to eq('A123E 45')
    end

    it 'expands braced macros' do
      expr = Makefile::Expression.new(
        macroset(
          'B' => 'b',
          'BCD' => '123',
          'FG' => '45',
        ),
        'A${BCD}E ${FG}'
      )
      result = expr.evaluate(double('target'))

      expect(result).to eq('A123E 45')
    end

    it 'expands undefined macros into blank' do
      expr = Makefile::Expression.new(macroset({}), 'A$BCD$(EF)G${HI}')
      result = expr.evaluate(double('target'))

      expect(result).to eq('ACDG')
    end

    it 'raises an exception on self-recursion' do
      expr = Makefile::Expression.new(
        macroset('A' => '_${A}'),
        '$A'
      )
      expect {
        expr.evaluate(double('target'))
      }.to raise_error(Makefile::Error)
    end

    it 'raises an exception on mutual recursion' do
      expr = Makefile::Expression.new(
        macroset(
          'A' => '_${B}',
          'B' => '-${A}',
        ),
        '$A'
      )
      expect {
        expr.evaluate(double('target'))
      }.to raise_error(Makefile::ParseError)
    end

    it 'expands $$ to $' do
      expr = Makefile::Expression.new(
        macroset('A' => 'a'),
        '$${A}'
      )
      result = expr.evaluate(double('target'))

      expect(result).to eq('${A}')
    end

    %w[ $($) ${$} ].each do |ref|
      it "does not expand #{ref} with the default rule" do
        expr = Makefile::Expression.new(macroset({}), ref)
        result = expr.evaluate(double('target'))

        expect(result).to eq("")
      end
    end

    it 'expands only once' do
      expr = Makefile::Expression.new(
        macroset(
          'M' => '$$',
          'N' => '(S)',
          'S' => '1',
          'T' => '$(M)$(N)',
        ),
        '$T',
      )
      result = expr.evaluate(double('target'))

      expect(result).to eq('$(S)')
    end

    it 'allows hook variables' do
      called = false

      target = double('target')
      macros = {}
      macros['A'] = Makefile::Macro.new(macros, 'A') do |t, m|
        called = true
        expect(t).to equal(target)
        expect(m).to eq(macros)

        'abcde'
      end

      expr = Makefile::Expression.new(macros, '$A')
      result = expr.evaluate(target)

      expect(called).to be_truthy
      expect(result).to eq('abcde')
    end

    it 'substitutes on macro expansion' do
      expr = Makefile::Expression.new(
        macroset(
          'A' => '$(B:.S=.o)',
          'B' => '$(C:.c=.S)',
          'C' => "foo.c bar.c\tbaz.c\vqux.c",
        ),
        '$A'
      )
      result = expr.evaluate(double('target'))

      expect(result).to eq("foo.o bar.o\tbaz.o\vqux.o")
    end

    it 'evaluates replacement text on expansion' do
      expr = Makefile::Expression.new(
        macroset(
          'A' => '$(B:.c=$S)',
          'B' => "foo.c bar.c\tbaz.c\vqux.c",
          'S' => '${T}',
          'T' => '.o',
        ),
        '$A'
      )
      result = expr.evaluate(double('target'))

      expect(result).to eq("foo.o bar.o\tbaz.o\vqux.o")
    end

    it 'replace patterns only before whitespace' do
      expr = Makefile::Expression.new(
        macroset('A' => "abc.abc abc-abc\tabc$$abc\vabc"),
        '$(A:abc=123)'
      )
      result = expr.evaluate(double('target'))
      expect(result).to eq("abc.123 abc-123\tabc$123\v123")
    end
  end
end
