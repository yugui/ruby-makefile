require_relative "spec_helper"
require 'makefile'

require 'stringio'

describe Makefile::Reader do
  it "reads input with #read_line" do
    input = double('input')
    expect(input).to receive(:each_line).and_yield("a=b").and_yield("b=c")

    Makefile::Reader.new(input).read
  end

  describe "#each" do
    it "accepts a macro" do
      input = StringIO.new(<<-EOF)
MACRO1=1
      EOF

      macro, = *Makefile::Reader.new(input).read
      expect(macro).to eq([:macro, "MACRO1", "1"])
    end

    it 'ignores whitespaces around macro assignment' do
      input = StringIO.new(<<-EOF)
MACRO1 =1
MACRO2= 2
MACRO3 = 3
MACRO4 \t\v=\t\v 4
      EOF

      macros = Makefile::Reader.new(input).read
      expect(macros).to all(respond_to(:to_ary))
      expect(macros.size).to be(4)

      macros.each.with_index do |macro, i|
        expect(macro).to eq([:macro, "MACRO#{i+1}", "#{i+1}"])
      end
    end

    it "reads multiline macro" do
      input = StringIO.new(<<-EOF)
MACRO1=1 \\
\t2\t\t\\
\v3\v\v\\
 4 \t\v
      EOF

      macro, = *Makefile::Reader.new(input).read
      expect(macro).to eq([:macro, "MACRO1", "1 2 3 4 \t\v"])
    end

    it "accepts a suffix rule" do
      input = StringIO.new(<<-EOF)
.c.o:
	$(CC) -c -o $@ $<
      EOF

      rule, command = *Makefile::Reader.new(input).read
      expect(rule).to eq([:suffix_rule, ".c", ".o"])
      expect(command).to eq([:command, "$(CC) -c -o $@ $<\n"])
    end

    it "accepts a suffix rule without target suffix" do
      input = StringIO.new(<<-EOF)
.c:
	$(CC) -o $@ $<
      EOF

      rule, command = *Makefile::Reader.new(input).read
      expect(rule).to eq([:suffix_rule, ".c", nil])
      expect(command).to eq([:command, "$(CC) -o $@ $<\n"])
    end

    it "reads multiline command" do
      input = StringIO.new(<<-EOF)
.c.o:
\t$(ECHO) \\
1 \\
\t2 \\
\v3 \t\v
      EOF

      rule, command = *Makefile::Reader.new(input).read
      expect(rule).to eq([:suffix_rule, ".c", ".o"])
      expect(command).to eq([:command, "$(ECHO) 1 2 3 \t\v\n"])
    end

    it 'reads a target' do
      input = StringIO.new(<<-EOF)
foo: 
\techo ok
      EOF

      target, command = *Makefile::Reader.new(input).read
      expect(target).to eq([:target, 'foo', ''])
      expect(command).to eq([:command, "echo ok\n"])
    end

    it 'reads a target with deps' do
      input = StringIO.new(<<-EOF)
foo: bar$(EXT) baz
	$(CC) -c -o foo bar baz
      EOF

      target, command = *Makefile::Reader.new(input).read
      expect(target).to eq([:target, 'foo', 'bar$(EXT) baz'])
      expect(command).to eq([:command, "$(CC) -c -o foo bar baz\n"])
    end

    it "skips comments" do
      input = StringIO.new(<<-EOF)
MACRO1=1# test
# MACRO2=2
      EOF

      constructs = Makefile::Reader.new(input).read
      expect(constructs.size).to eq(1)
      expect(constructs.first).to eq([:macro, "MACRO1", "1"])
    end
  end
end
