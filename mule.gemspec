# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "mule/version"

Gem::Specification.new do |s|
  s.name        = "mule"
  s.version     = Mule::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Tyler Flint"]
  s.email       = ["tylerflint@gmail.com"]
  s.homepage    = "http://rubygems.org/gems/mule"
  s.summary     = %q{tool for launching and reloading ruby jobs quickly and effeciently.}
  s.description = %q{Tool for launching and reloading ruby jobs. Expects jobs to handle signals and cleanup before killing.}

  s.rubyforge_project = "mule"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec", "~> 1.3.0"
end
