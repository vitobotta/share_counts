# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
$:.push File.expand_path("../lib/share_counts", __FILE__)

Gem::Specification.new do |s|
  s.name        = "share_counts"
  s.version     = "0.1.4"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Vito Botta"]
  s.email       = ["vito@botta.name"]
  s.homepage    = "https://github.com/vitobotta/share_counts"
  s.summary     = %q{The easiest way to check how many times a URL has been shared on Reddit, Digg, Twitter, Facebook, LinkedIn, GoogleBuzz and StumbleUpon!}
  s.description = %q{The easiest way to check how many times a URL has been shared on Reddit, Digg, Twitter, Facebook, LinkedIn, GoogleBuzz and StumbleUpon!}

  s.add_dependency "rest-client"
  s.add_dependency "json"
  s.add_dependency "nokogiri"
  s.add_dependency "redis"

  s.add_development_dependency "webmock"
  s.add_development_dependency "activesupport"
  s.add_development_dependency "autotest-growl"
  s.add_development_dependency "autotest-fsevent"
  s.add_development_dependency "redgreen"
  
  s.rubyforge_project = "share_counts"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
