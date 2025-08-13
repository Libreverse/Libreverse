# -*- encoding: utf-8 -*-
# stub: rodauth-rails 2.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "rodauth-rails".freeze
  s.version = "2.1.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Janko Marohni\u0107".freeze]
  s.date = "2025-03-19"
  s.description = "Provides Rails integration for Rodauth authentication framework.".freeze
  s.email = ["janko.marohnic@gmail.com".freeze]
  s.homepage = "https://github.com/janko/rodauth-rails".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.6".freeze)
  s.rubygems_version = "3.6.2".freeze
  s.summary = "Provides Rails integration for Rodauth authentication framework.".freeze

  s.installed_by_version = "3.6.2".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<railties>.freeze, [">= 5.1".freeze, "< 8.1".freeze])
  s.add_runtime_dependency(%q<rodauth>.freeze, ["~> 2.36".freeze])
  s.add_runtime_dependency(%q<roda>.freeze, ["~> 3.76".freeze])
  s.add_runtime_dependency(%q<rodauth-model>.freeze, ["~> 0.2".freeze])
  s.add_development_dependency(%q<tilt>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<bcrypt>.freeze, ["~> 3.1".freeze])
  s.add_development_dependency(%q<jwt>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rotp>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rqrcode>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<webauthn>.freeze, [">= 0".freeze])
end
