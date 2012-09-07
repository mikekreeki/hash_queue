# -*- encoding: utf-8 -*-
require File.expand_path('../lib/hash_queue/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Michal Krejci"]
  gem.email         = ["mikekreeki@gmail.com"]
  gem.description   = %q{Threadsafe namespaced Queue with locking.}
  gem.summary       = %q{Threadsafe namespaced Queue with locking.}
  gem.homepage      = ""

  gem.add_development_dependency('minitest')
  
  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "hash_queue"
  gem.require_paths = ["lib"]
  gem.version       = HashQueue::VERSION
end
