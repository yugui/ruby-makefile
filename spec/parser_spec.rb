require_relative "spec_helper"
require 'makefile'

describe Makefile::Parser do
  let(:reader_class) do
    class_double('Makefile::Reader')
      .as_stubbed_const(:transfer_nested_constants => true)
  end

  let(:reader) { instance_double('Makefile::Reader') }
  let(:parser) { Makefile::Parser.new }


  it 'calls #each on the reader' do
    input = double(:input)
    expect(reader_class).to receive(:new).with(input).and_return(reader)
    expect(reader).to receive(:each)

    parser.parse(input)
  end

  def stub_input(*sequence)
    input = double(:input)
    allow(reader_class).to receive(:new).with(input).and_return(reader)
    behavior = sequence.inject(receive(:each)) do |expectation, construct|
      expectation.and_yield(construct)
    end
    allow(reader).to behavior
    allow(reader).to receive(:lineno).and_return(double(:lineno))
    input
  end

  it 'parses a macro' do
    input = stub_input(
      [:macro, 'A', 'a'],
    )

    parser.parse(input)
    macroset, _, _ = parser.result

    expect(macroset['A']).to be_an_instance_of(Makefile::Macro)
    expect(macroset['A'].name).to eq('A')
    expect(macroset['A'].raw_value).to eq('a')
  end

  it 'parses macro sequence' do
    input = stub_input(
      [:macro, 'A', 'a'],
      [:macro, 'B', '$(A)'],
    )

    parser.parse(input)
    macroset, _, _ = parser.result

    expect(macroset['A']).to be_an_instance_of(Makefile::Macro)
  end

  it 'does not allow overwriting macro' do
    input = stub_input(
      [:macro, 'A', 'a'],
      [:macro, 'A', 'b'],
    )
    expect {
      parser.parse(input)
    }.to raise_error(Makefile::ParseError)
  end

  it 'does not allow macro to have two same definitions' do
    input = stub_input(
      [:macro, 'A', 'a'],
      [:macro, 'A', 'a'],
    )
    expect {
      parser.parse(input)
    }.not_to raise_error(Makefile::ParseError)
  end

  it 'parses a suffix rule' do
    input = stub_input(
      [:suffix_rule, '.c', '.o'],
    )

    parser.parse(input)
    _, suffix_rules, _ = parser.result

    expect(suffix_rules['.o']).to all(be_an_instance_of(Makefile::SuffixRule))
    expect(suffix_rules['.o']).to all(satisfy {|rule| rule.target == '.o' })
    expect(suffix_rules['.o'].size).to eq(1)
    expect(suffix_rules['.o'][0].source).to eq('.c')
  end

  it 'allows multiple suffix rules for a target' do
    input = stub_input(
      [:suffix_rule, '.c', '.o'],
      [:suffix_rule, '.S', '.o'],
    )

    parser.parse(input)
    _, suffix_rules, _ = parser.result

    expect(suffix_rules['.o']).to all(be_an_instance_of(Makefile::SuffixRule))
    expect(suffix_rules['.o']).to all(satisfy {|rule| rule.target == '.o' })
    expect(suffix_rules['.o'].size).to eq(2)

    expect(suffix_rules['.o'][0].source).to eq('.c')
    expect(suffix_rules['.o'][1].source).to eq('.S')
  end

  it 'associates commands to suffix rules' do
    input = stub_input(
      [:suffix_rule, '.c', '.o'],
      [:command, 'echo 1 > $<'],
      [:command, 'echo 2 >> $<'],
    )
    parser.parse(input)
    _, suffix_rules, _ = parser.result

    expect(suffix_rules['.o']).to all(be_an_instance_of(Makefile::SuffixRule))
    expect(suffix_rules['.o']).to all(satisfy {|rule| rule.target == '.o' })
    expect(suffix_rules['.o'].size).to eq(1)

    rule = suffix_rules['.o'][0]
    expect(rule.commands).to all(be_an_instance_of(Makefile::Command))
    expect(rule.commands.size).to eq(2)
    expect(rule.commands[0].raw_cmd).to eq('echo 1 > $<')
    expect(rule.commands[1].raw_cmd).to eq('echo 2 >> $<')
  end

  it 'parses a target' do
    input = stub_input(
      [:target, 'foo', ''],
    )
    parser.parse(input)
    _, _, targets = parser.result

    expect(targets['foo']).to be_an_instance_of(Makefile::Target)
    expect(targets['foo'].name).to eq('foo')
    expect(targets['foo'].raw_deps).to eq([''])
  end

  it 'parses a target with deps' do
    input = stub_input(
      [:target, 'foo', 'bar $(BAZ) qux'],
    )
    parser.parse(input)
    _, _, targets = parser.result

    expect(targets['foo']).to be_an_instance_of(Makefile::Target)
    expect(targets['foo'].name).to eq('foo')
    expect(targets['foo'].raw_deps).to eq(['bar $(BAZ) qux'])
  end

  it 'allowes adding dependencies' do
    input = stub_input(
      [:target, 'foo', 'bar $(BAZ) qux'],
      [:target, 'foo', '${A} B C'],
    )
    parser.parse(input)
    _, _, targets = parser.result

    expect(targets['foo']).to be_an_instance_of(Makefile::Target)
    expect(targets['foo'].name).to eq('foo')
    expect(targets['foo'].raw_deps).to eq([
      'bar $(BAZ) qux',
      '${A} B C',
    ])
  end

  it 'associates commands to targets' do
    input = stub_input(
      [:target, 'foo', ''],
      [:command, 'echo 1'],
      [:command, 'echo 2'],
    )
    parser.parse(input)
    _, _, targets = parser.result

    expect(targets['foo']).to be_an_instance_of(Makefile::Target)
    expect(targets['foo'].name).to eq('foo')
    expect(targets['foo'].commands).to all(be_an_instance_of(Makefile::Command))
    expect(targets['foo'].commands.size).to eq(2)
    expect(targets['foo'].commands[0].raw_cmd).to eq('echo 1')
    expect(targets['foo'].commands[1].raw_cmd).to eq('echo 2')
  end

  it 'does not allow unassociated commands' do
    input = stub_input(
      [:command, 'echo 1'],
    )
    expect {
      parser.parse(input)
    }.to raise_error(Makefile::ParseError)
  end

  it 'accepts null input' do
    input = stub_input

    parser.parse(input)
    macroset, rules, targets = parser.result

    expect(macroset.values).to all(be_an_instance_of(Makefile::Macro))
    expect(rules).to be_empty
    expect(targets).to be_empty
  end

  it 'returns self' do
    input = stub_input
    ret = parser.parse(input)
    expect(ret).to equal(parser)
  end
end
