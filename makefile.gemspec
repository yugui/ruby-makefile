# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'makefile/version'

Gem::Specification.new do |spec|
  spec.name          = "makefile"
  spec.version       = Makefile::VERSION
  spec.authors       = ["Yuki Yugui Sonoda"]
  spec.email         = ["yugui@yugui.jp"]
  spec.description   = %q{Makefile parser}
  spec.summary       = %q{Makefile parser}
  spec.homepage      = "https://github.com/yugui/ruby-makefile"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.1"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rr"
end
