# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "torquespec/version"

Gem::Specification.new do |s|
  s.name        = "torquespec"
  s.version     = TorqueSpec::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jim Crossley", "Bob McWhirter"]
  s.email       = "team@projectodd.org"
  s.homepage    = "http://github.com/torquebox/torquespec"
  s.summary     = %q{Deploy TorqueBox knobs to a running JBoss instance}
  s.description = %q{Write integration tests around the deployment of your app to a real JBoss app server}

  s.rubyforge_project = "torquespec"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "rspec"
  s.add_dependency "json"
end
