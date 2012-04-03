# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "heimdallr-resource"
  s.version     = "1.0.0.RC1"
  s.authors     = ["Peter Zotov", "Boris Staal"]
  s.email       = ["whitequark@whitequark.org", "boris@roundlake.ru"]
  s.homepage    = "http://github.com/roundlake/heimdallr-resource"
  s.summary     = %q{Heimdallr-Resource provides CanCan-like interface for Heimdallr-secured objects.}
  s.description = s.summary

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "activerecord"
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "tzinfo"
  s.add_runtime_dependency "heimdallr"
end
