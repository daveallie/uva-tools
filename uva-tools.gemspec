# -*- encoding: utf-8 -*-
$: << File.expand_path('../lib', __FILE__)
require 'uva-tools/version'

Gem::Specification.new do |gem|
  gem.authors       = "Dave Allie"
  gem.email         = "dave@daveallie.com"
  gem.description   = "Set of UVa Online tools"
  gem.summary       = gem.description
  gem.homepage      = "https://github.com/daveallie/uva-tools"
  gem.license       = 'MIT'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "uva-tools"
  gem.require_paths = ["lib"]
  gem.version       = UVaTools::VERSION
end
