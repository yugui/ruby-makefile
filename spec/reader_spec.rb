require_relative "spec_helper"
require 'makefile'

describe Makefile::Reader do
  def create_input_stub(lines)
    lines = lines.dup
    input = double('input')
    allow(input).to receive(:eof?) { lines.empty? }
    allow(input).to receive(:read_line) { lines.shift }
    input
  end

  it "reads input with #read_line" do
    eof = false
    input = double('input')
    allow(input).to receive(:eof?) { eof }
    expect(input).to receive(:read_line) { "a=b\n" }
    expect(input).to receive(:read_line) { eof = true; "b=c" }

    Makefile::Reader.new(input).read
  end

  describe "#each" do
    it "returns a Macro object on read a macro" do
      input = create_input_stub(<<-EOF.lines)
MACRO1=1
      EOF

      macro, = *Makefile::Reader.new(input).read
      expect(macro).to be_an_instance_of(Makefile::Macro)
      expect(macro.name).to eq("MACRO1")
      expect(macro.raw_value).to eq("1")
    end

    it 'ignores whitespaces around macro assignment' do
      input = create_input_stub(<<-EOF.lines)
MACRO1 =1
MACRO2= 2
MACRO3 = 3
MACRO4 \t\v=\t\v 4
      EOF

      macros = Makefile::Reader.new(input).read
      expect(macros).to all(be_an_instance_of(Makefile::Macro))
      expect(macros.size).to be(4)

      macros.each.with_index do |macro, i|
        expect(macro.name).to eq("MACRO#{i+1}")
        expect(macro.raw_value).to eq("#{i+1}")
      end
    end

    it "returns a SuffixRule object on read a rule definition" do
      input = create_input_stub(<<-EOF.lines)
.c.o:
	$(CC) -c -o $@ $<
      EOF

      rule, = *Makefile::Reader.new(input).read
      expect(rule).to be_an_instance_of(Makefile::SuffixRule)
      expect(rule.source).to eq(".c")
      expect(rule.target).to eq(".o")
      expect(rule.commands.size).to eq(1)
      expect(rule.commands[0]).to eq(
        Makefile::Command.new("$(CC) -c -o $@ $<\n", rule))
    end

    it 'returns a Target object on reading a target definition' do
      input = create_input_stub(<<-EOF.lines)
foo: bar$(EXT) baz
	$(CC) -c -o foo bar baz
      EOF

      target, = *Makefile::Reader.new(input).read
      expect(target).to be_an_instance_of(Makefile::Target)
      expect(target.name).to eq('foo')
      expect(target.raw_deps).to eq(['bar$(EXT) baz'])
      expect(target.commands.size).to eq(1)
      expect(target.commands[0]).to eq(
        Makefile::Command.new("$(CC) -c -o foo bar baz\n", target))
    end

    it "skips comments" do
      input = create_input_stub(<<-EOF.lines)
MACRO1=1# test
# MACRO2=2
      EOF

      iter = Makefile::Reader.new(input).enum_for(:each)
      macro = iter.next
      expect(macro).to be_an_instance_of(Makefile::Macro)
      expect(macro.name).to eq("MACRO1")
      expect(macro.raw_value).to eq("1")
      expect { iter.next }.to raise_error(StopIteration)
    end
  end
end
