# -*- encoding: utf-8 -*-
# stub: zip_kit 6.3.3 ruby lib

Gem::Specification.new do |s|
  s.name = "zip_kit".freeze
  s.version = "6.3.3".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "https://rubygems.org", "changelog_uri" => "https://github.com/julik/zip_kit/blob/main/CHANGELOG.md", "homepage_uri" => "https://github.com/julik/zip_kit", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/julik/zip_kit" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Julik Tarkhanov".freeze, "Noah Berman".freeze, "Dmitry Tymchuk".freeze, "David Bosveld".freeze, "Felix B\u00FCnemann".freeze]
  s.bindir = "exe".freeze
  s.date = "2025-04-18"
  s.description = "Stream out ZIP files from Ruby. Successor to zip_tricks.".freeze
  s.email = ["me@julik.nl".freeze]
  s.homepage = "https://github.com/julik/zip_kit".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.6.0".freeze)
  s.rubygems_version = "3.6.2".freeze
  s.summary = "Stream out ZIP files from Ruby. Successor to zip_tricks.".freeze

  s.installed_by_version = "3.6.2".freeze

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rubyzip>.freeze, ["~> 2".freeze])
  s.add_development_dependency(%q<rack>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 12.2".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3".freeze])
  s.add_development_dependency(%q<rspec-mocks>.freeze, ["~> 3.10".freeze, ">= 3.10.2".freeze])
  s.add_development_dependency(%q<complexity_assert>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<coderay>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<benchmark-ips>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<allocation_stats>.freeze, ["~> 0.1.5".freeze])
  s.add_development_dependency(%q<yard>.freeze, ["~> 0.9".freeze])
  s.add_development_dependency(%q<standard>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<magic_frozen_string_literal>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<puma>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<mutex_m>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<bigdecimal>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rails>.freeze, ["~> 5".freeze])
  s.add_development_dependency(%q<actionpack>.freeze, ["~> 5".freeze])
  s.add_development_dependency(%q<nokogiri>.freeze, ["~> 1".freeze, ">= 1.13".freeze])
  s.add_development_dependency(%q<sinatra>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<sord>.freeze, [">= 0".freeze])
end
