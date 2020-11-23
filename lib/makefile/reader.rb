require 'makefile/command'
require 'makefile/target'
require 'makefile/errors'

class Makefile::Reader
  include Enumerable

  def initialize(input)
    @input = input
  end

  def each
    rule = nil
    while line = read_line
      next if line.chomp.empty?
      if line.start_with?("\t")
        raise Makefile::ParseError, "commands outside of rule at line #{lineno}" unless rule
        command = Makefile::Command.new(line[1..-1])
        rule.add_command(command)
        next
      else
        yield rule if rule
        rule = nil
      end

      case line
      when /\A([[:alpha:]_.][[:alnum:]_.-]*)\s*=\s*(.*)$/
        yield Makefile::Macro.new($1, $2)
      when /^(\.[^.]+)(\.[^.]+)?:$/
        rule = Makefile::SuffixRule.new($1, $2)
      when /^(.+):(.*)$/
        rule = Makefile::Target.new($1, raw_deps: $2.strip)
      else
        raise NotImplementedError, "Unrecognized line #{line.dump} at #{lineno}"
      end
    end
    yield rule if rule
  end

  def read
    to_a
  end

  private
  def read_line
    return nil if @input.eof?
    line = ""
    begin
      fragment = @input.readline
      fragment = fragment.sub(/#.*$/, '')
      line << fragment
    end while !@input.eof? and line.sub!(/\\\r?\n?/, ' ')
    return line
  end

  def lineno
    @input.lineno
  end
end
