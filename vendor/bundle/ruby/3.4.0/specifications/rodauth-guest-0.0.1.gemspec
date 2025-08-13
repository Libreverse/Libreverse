# -*- encoding: utf-8 -*-
# stub: rodauth-guest 0.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "rodauth-guest".freeze
  s.version = "0.0.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "homepage_uri" => "https://github.com/janko/rodauth-guest", "source_code_uri" => "https://github.com/janko/rodauth-guest" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Janko Marohni\u0107".freeze]
  s.date = "2022-10-11"
  s.email = ["janko@hey.com".freeze]
  s.homepage = "https://github.com/janko/rodauth-guest".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3".freeze)
  s.rubygems_version = "3.3.3".freeze
  s.summary = "Provides guest users functionality for Rodauth.".freeze

  s.installed_by_version = "3.6.2".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<rodauth>.freeze, ["~> 2.0".freeze])
  s.add_development_dependency(%q<minitest>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<minitest-hooks>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<capybara>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<sqlite3>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<tilt>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<bcrypt>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<mail>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<net-smtp>.freeze, [">= 0".freeze])
end
