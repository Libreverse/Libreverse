# -*- encoding: utf-8 -*-
# stub: rodauth-pwned 0.2.1 ruby lib

Gem::Specification.new do |s|
  s.name = "rodauth-pwned".freeze
  s.version = "0.2.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "homepage_uri" => "https://github.com/janko/rodauth-pwned", "source_code_uri" => "https://github.com/janko/rodauth-pwned" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Janko Marohni\u0107".freeze]
  s.date = "2023-03-16"
  s.description = "Rodauth extension for checking whether a password had been exposed in a database breach according to https://haveibeenpwned.com.".freeze
  s.email = ["janko.marohnic@gmail.com".freeze]
  s.homepage = "https://github.com/janko/rodauth-pwned".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3.0".freeze)
  s.rubygems_version = "3.4.7".freeze
  s.summary = "Rodauth extension for checking whether a password had been exposed in a database breach according to https://haveibeenpwned.com.".freeze

  s.installed_by_version = "3.6.2".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<rodauth>.freeze, ["~> 2.0".freeze])
  s.add_runtime_dependency(%q<pwned>.freeze, ["~> 2.1".freeze])
  s.add_development_dependency(%q<minitest>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<minitest-hooks>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<tilt>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<bcrypt>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<capybara>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rodauth-i18n>.freeze, [">= 0".freeze])
end
