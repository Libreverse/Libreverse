# -*- encoding: utf-8 -*-
# stub: graphql_rails 3.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "graphql_rails".freeze
  s.version = "3.1.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Povilas Jur\u010Dys".freeze]
  s.bindir = "exe".freeze
  s.date = "2025-05-26"
  s.email = ["po.jurcys@gmail.com".freeze]
  s.homepage = "https://github.com/samesystem/graphql_rails".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.3.7".freeze
  s.summary = "Rails style structure for GraphQL API.".freeze

  s.installed_by_version = "3.6.2".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<graphql>.freeze, ["~> 2".freeze])
  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 4".freeze])
  s.add_development_dependency(%q<bundler>.freeze, ["~> 2".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0".freeze])
  s.add_development_dependency(%q<activerecord>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<pry-byebug>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rails>.freeze, ["~> 6".freeze])
end
