# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "httparrot/version"

Gem::Specification.new do |s|
  s.name        = "httparrot"
  s.version     = HTTParrot::VERSION
  s.authors     = ["Brandon Dewitt"]
  s.email       = ["brandonsdewitt@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Mock Server for testing HTTP anything!}
  s.description = %q{helps cut through the clutter of HTTP testing}

  s.rubyforge_project = "httparrot"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_development_dependency "rspec", "=2.7"
  s.add_development_dependency "rake"

  s.add_runtime_dependency "rack"
  s.add_runtime_dependency "active_support"
end
