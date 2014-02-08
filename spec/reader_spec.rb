require_relative "spec_helper"
require 'makefile'

describe Makefile::Reader do
  def create_input_stub(lines)
    lines = lines.dup
    input = Object.new
    stub(input).eof? { lines.empty? }
    stub(input).read_line { lines.shift }
    input
  end

  it "reads input with #read_line" do
    eof = false
    input = Object.new
    stub(input).eof? { eof }
    mock(input).read_line { "a=b\n" }
    mock(input).read_line { eof = true; "b=c" }
    Makefile::Reader.new(input).read
  end

  describe "#read_element" do

    it "returns a Macro object on read a macro" do
      input = create_input_stub(<<-EOF.lines)
MACRO1=1
      EOF

      macro = Makefile::Reader.new(input).read_element
      expect(macro).to be_an_instance_of(Makefile::Macro)
      expect(macro.name).to eq("MACRO1")
      expect(macro.raw_value).to eq("1")
    end

    it "returns nil after read all elements" do
      expect(
        Makefile::Reader.new(create_input_stub([])).read_element
      ).to be_nil

      input = create_input_stub(<<-EOF.lines)
MACRO1=1
      EOF
      reader = Makefile::Reader.new(input)
      reader.read_element
      expect(reader.read_element).to be_nil
    end

    it "skips comments" do
      input = create_input_stub(<<-EOF.lines)
MACRO1=1# test
# MACRO2=2
      EOF

      reader = Makefile::Reader.new(input)
      macro = reader.read_element
      expect(macro).to be_an_instance_of(Makefile::Macro)
      expect(macro.name).to eq("MACRO1")
      expect(macro.raw_value).to eq("1")
      expect(reader.read_element).to be_nil
    end
    
  end
end
