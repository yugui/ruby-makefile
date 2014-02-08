module Makefile; end

class Makefile::Reader
  include Enumerable

  def initialize(input)
    @input = input
  end

  def read_element
    begin
      line = read_line
      return if line.nil?
    end while line.chomp.empty?
    case line
    when /\A([[:alpha:]][[:alnum:]]*)=(.*)$/
      return Makefile::Macro.new($1, $2)
    else
      raise NotImplementedError
    end
  end

  def each
    while element = read_element
      yield element
    end
  end

  def read
    to_a
  end

  private
  def read_line
    return nil if @input.eof?
    line = ""
    begin
      fragment = @input.read_line
      fragment = fragment.sub(/#.*$/, '')
      line << fragment
    end while !@input.eof? and line.end_with?('\\')
    return line
  end
end
