# -*- encoding: utf-8 -*-
# stub: rodauth-omniauth 0.6.1 ruby lib

Gem::Specification.new do |s|
  s.name = "rodauth-omniauth".freeze
  s.version = "0.6.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "homepage_uri" => "https://github.com/janko/rodauth-omniauth", "source_code_uri" => "https://github.com/janko/rodauth-omniauth" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Janko Marohni\u0107".freeze]
  s.date = "1980-01-02"
  s.description = "Rodauth extension for logging in and creating account via OmniAuth authentication.".freeze
  s.email = ["janko@hey.com".freeze]
  s.homepage = "https://github.com/janko/rodauth-omniauth".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5".freeze)
  s.rubygems_version = "3.6.9".freeze
  s.summary = "Rodauth extension for logging in and creating account via OmniAuth authentication.".freeze

  s.installed_by_version = "3.6.2".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<rodauth>.freeze, ["~> 2.36".freeze])
  s.add_runtime_dependency(%q<omniauth>.freeze, ["~> 2.0".freeze])
  s.add_development_dependency(%q<minitest>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<minitest-hooks>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<tilt>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<bcrypt>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<mail>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<net-smtp>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<capybara>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<jwt>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rodauth-i18n>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rodauth-model>.freeze, [">= 0".freeze])
end
