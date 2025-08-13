# -*- encoding: utf-8 -*-
# stub: voight_kampff 2.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "voight_kampff".freeze
  s.version = "2.0.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Adam Crownoble".freeze]
  s.date = "2023-03-12"
  s.description = "Voight-Kampff detects bots, spiders, crawlers and replicants".freeze
  s.email = "adam@codenoble.com".freeze
  s.homepage = "https://github.com/biola/Voight-Kampff".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.0.3.1".freeze
  s.summary = "Voight-Kampff bot detection".freeze

  s.installed_by_version = "3.6.2".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<rack>.freeze, [">= 1.4".freeze])
  s.add_development_dependency(%q<combustion>.freeze, ["~> 1.1".freeze])
  s.add_development_dependency(%q<rails>.freeze, [">= 5.2".freeze])
  s.add_development_dependency(%q<rspec-rails>.freeze, ["~> 3.8".freeze])
end
