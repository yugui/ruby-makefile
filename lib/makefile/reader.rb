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
    each_logical_line do |line|
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

  # @return [Array<Macro, SuffixRule, Target>] top-level constructs of the makefile.
  def read
    to_a
  end

  private
  def each_logical_line
    line = ""
    @input.each_line do |fragment|
      fragment = fragment.sub(/#.*$/, '')
      line << fragment
      unless line.sub!(/\\\r?\n?/, ' ')
        yield line
        line = ""
      end
    end
    yield line unless line.empty?
  end

  def lineno
    if @input.respond_to?(:lineno)
      @input.lineno
    else
      '(unknown)'
    end
  end
end
