# -*- encoding: utf-8 -*-
# stub: swd 1.3.0 ruby lib

Gem::Specification.new do |s|
  s.name = "swd".freeze
  s.version = "1.3.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["nov matake".freeze]
  s.date = "2021-10-01"
  s.description = "SWD (Simple Web Discovery) Client Library".freeze
  s.email = ["nov@matake.jp".freeze]
  s.homepage = "https://github.com/nov/swd".freeze
  s.rubygems_version = "3.1.4".freeze
  s.summary = "SWD (Simple Web Discovery) Client Library".freeze

  s.installed_by_version = "3.6.2".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<httpclient>.freeze, [">= 2.4".freeze])
  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 3".freeze])
  s.add_runtime_dependency(%q<attr_required>.freeze, [">= 0.0.5".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec-its>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<webmock>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, [">= 0".freeze])
end
