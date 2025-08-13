# -*- encoding: utf-8 -*-
# stub: openid_connect 1.4.2 ruby lib

Gem::Specification.new do |s|
  s.name = "openid_connect".freeze
  s.version = "1.4.2".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["nov matake".freeze]
  s.date = "2022-10-08"
  s.description = "OpenID Connect Server & Client Library".freeze
  s.email = ["nov@matake.jp".freeze]
  s.homepage = "https://github.com/nov/openid_connect".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.3.7".freeze
  s.summary = "OpenID Connect Server & Client Library".freeze

  s.installed_by_version = "3.6.2".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<tzinfo>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<attr_required>.freeze, [">= 1.0.0".freeze])
  s.add_runtime_dependency(%q<activemodel>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<validate_url>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<validate_email>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<json-jwt>.freeze, [">= 1.15.0".freeze])
  s.add_runtime_dependency(%q<swd>.freeze, ["~> 1.3".freeze])
  s.add_runtime_dependency(%q<webfinger>.freeze, ["~> 1.2".freeze])
  s.add_runtime_dependency(%q<rack-oauth2>.freeze, ["~> 1.21".freeze])
  s.add_runtime_dependency(%q<net-smtp>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec-its>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<webmock>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rexml>.freeze, [">= 0".freeze])
end
