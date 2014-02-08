module Makefile; end

class Makefile::Macro
  def initialize(name, raw_value)
    @name = name
    @raw_value = raw_value
    #TODO(yugui) parse value
  end
  attr_reader :name, :raw_value
end
