require 'makefile/command'
require 'makefile/target'
require 'makefile/errors'

class Makefile::Reader
  include Enumerable

  # @param input [#each_line] Reads a Makefile from this source.
  def initialize(input)
    @input = input
  end

  # @yieldparam [Macro, SuffixRule, Target] a top-level construct of makefile
  def each
    each_logical_line do |line|
      next if line.chomp.empty?
      if line.start_with?("\t")
        yield :command, line[1..-1]
        next
      end

      case line
      when /\A([[:alpha:]_.][[:alnum:]_.-]*)\s*=\s*(.*)$/
        yield :macro, $1, $2
      when /^(\.[^.]+)(\.[^.]+)?:$/
        yield :suffix_rule, $1, $2
      when /^(.+):(.*)$/
        yield :target, $1, $2.strip
      else
        raise NotImplementedError, "Unrecognized line #{line.dump} at #{lineno}"
      end
    end
  end

  # @return [Array<Macro, SuffixRule, Target>] top-level constructs of the makefile.
  def read
    to_a
  end

  def lineno
    if @input.respond_to?(:lineno)
      @input.lineno
    else
      '(unknown)'
    end
  end

  private
  def each_logical_line
    line = ""
    @input.each_line do |fragment|
      fragment = fragment.sub(/#.*$/, '')

      # Leading whitespaces are ignored on line continuation
      fragment.sub!(/\A\s+/, '') unless line.empty?
      line << fragment

      unless line.sub!(/\s*\\\r?\n?/, ' ')
        yield line
        line = ""
      end
    end
    yield line unless line.empty?
  end
end
