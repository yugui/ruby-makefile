require 'makefile/errors'
require 'makefile/reader'

module Makefile
  class Parser
    def initialize
      @macroset = {}.tap do |macroset|
        macroset['$'] = Macro.new(macroset, '$', '$', allow_quoted: false)
      end
      @suffix_rules = {}
      @targets = {}
    end

    def parse_file(path, *args, **opts)
      File.open(path, *args, **opts) do |f|
        parse(f)
      end
    end

    def parse(input)
      reader = Reader.new(input)
      rule = nil
      reader.each do |type, *opts|
        case type
        when :macro
          name, value, = *opts
          if @macroset[name]
            raise ParseError, "Macro #{name} is already defined" unless \
              @macroset[name].raw_value == value
          else
            @macroset[name] = Macro.new(@macroset, name, value)
          end
          rule = nil

        when :suffix_rule
          source, target = *opts
          rule = SuffixRule.new(@macroset, source, target)
          (@suffix_rules[target] ||= []) << rule

        when :target
          name, raw_deps, = *opts
          rule = @targets[name] ||= Target.new(@macroset, name)
          rule.add_dependency(raw_deps)

        when :command
          raw_cmd, = *opts
          raise ParseError, "commands outside of rule: line #{reader.lineno}" \
            unless rule
          rule.add_command(Command.new(@macroset, raw_cmd))
        end
      end
      self
    end

    def result
      return @macroset, @suffix_rules, @targets
    end
  end
end
