# -*- encoding: utf-8 -*-
# stub: re2 2.18.0 x86_64-linux-gnu lib

Gem::Specification.new do |s|
  s.name = "re2".freeze
  s.version = "2.18.0".freeze
  s.platform = "x86_64-linux-gnu".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 3.3.22".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Paul Mucur".freeze, "Stan Hu".freeze]
  s.date = "2025-08-03"
  s.description = "Ruby bindings to RE2, \"a fast, safe, thread-friendly alternative to backtracking regular expression engines like those used in PCRE, Perl, and Python\".".freeze
  s.homepage = "https://github.com/mudge/re2".freeze
  s.licenses = ["BSD-3-Clause".freeze]
  s.required_ruby_version = Gem::Requirement.new([">= 2.6".freeze, "< 3.5.dev".freeze])
  s.rubygems_version = "3.3.27".freeze
  s.summary = "Ruby bindings to RE2.".freeze

  s.installed_by_version = "3.6.2".freeze

  s.specification_version = 4

  s.add_development_dependency(%q<rake-compiler>.freeze, ["~> 1.2.7".freeze])
  s.add_development_dependency(%q<rake-compiler-dock>.freeze, ["~> 1.9.1".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.2".freeze])
end
