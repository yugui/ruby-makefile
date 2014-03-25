require 'shellwords'

module Makefile
  class Command
    def initialize(raw_cmd, rule)
      @rule = rule
      @argv = Shellwords.split(raw_cmd).map do |arg|
        arg
      end
    end

    def ==(rhs)
      self.rule == rhs.rule and self.argv == rhs.argv
    end

    protected
    attr_reader :rule, :argv
  end

  class Command::Literal < String
    def expand(rule, macroset)
      to_s
    end
  end

  class Command::MacroRef
    def initialize(source)
    end
  end

  class Command::Concat
    def initialize(source)
    end
  end
end
