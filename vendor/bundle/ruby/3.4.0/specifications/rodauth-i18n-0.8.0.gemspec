# -*- encoding: utf-8 -*-
# stub: rodauth-i18n 0.8.0 ruby lib

Gem::Specification.new do |s|
  s.name = "rodauth-i18n".freeze
  s.version = "0.8.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Janko Marohni\u0107".freeze]
  s.date = "2024-10-12"
  s.email = ["janko@hey.com".freeze]
  s.homepage = "https://github.com/janko/rodauth-i18n".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5".freeze)
  s.rubygems_version = "3.5.11".freeze
  s.summary = "Provides I18n integration and translations for Rodauth authentication framework.".freeze

  s.installed_by_version = "3.6.2".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<rodauth>.freeze, ["~> 2.19".freeze])
  s.add_runtime_dependency(%q<i18n>.freeze, ["~> 1.0".freeze])
  s.add_development_dependency(%q<minitest>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<minitest-hooks>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<capybara>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<tilt>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<bcrypt>.freeze, [">= 0".freeze])
end
