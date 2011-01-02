# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "tableless_model/version"

Gem::Specification.new do |s|
  s.name        = "tableless_model"
  s.version     = TablelessModel::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Vito Botta"]
  s.email       = ["vito@botta.name"]
  s.homepage    = "http://rubygems.org/gems/tableless_model"
  s.summary     = %q{A serialisable, table-less model for ActiveRecord useful to store settings, options, etc in a parent object}
  s.description = %q{A serialisable, table-less model for ActiveRecord useful to store settings, options, etc in a parent object}
  
  s.add_dependency("hashie")
  s.add_dependency("validatable")


  s.rubyforge_project = "tableless_model"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
