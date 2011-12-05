# -*- encoding: utf-8 -*-
require File.expand_path('../lib/handy_capper/version', __FILE__)

Gem::Specification.new do |s|
  s.add_development_dependency('ruby-debug19')
  s.add_development_dependency('minitest')
  s.authors = ["Claude Nix"]
  s.description = %q{A Ruby library for calculating corrected scores for common sailboat racing scoring systems}
  s.email = ['claude@seadated.com']
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.files = `git ls-files`.split("\n")
  s.homepage = 'https://github.com/cnix/handy_capper'
  s.name = 'handy_capper'
  s.platform = Gem::Platform::RUBY
  s.require_paths = ['lib']
  s.required_rubygems_version = Gem::Requirement.new('>= 1.3.6') if s.respond_to? :required_rubygems_version=
  s.rubyforge_project = s.name
  s.summary = %q{A Ruby library for calculating corrected scores for common sailboat racing scoring systems}
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.version = HandyCapper::VERSION.dup
end
