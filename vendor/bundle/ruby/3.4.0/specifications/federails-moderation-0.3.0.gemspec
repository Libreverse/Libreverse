# -*- encoding: utf-8 -*-
# stub: federails-moderation 0.3.0 ruby lib

Gem::Specification.new do |s|
  s.name = "federails-moderation".freeze
  s.version = "0.3.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/manyfold3d/federails-moderation/releases", "homepage_uri" => "https://github.com/manyfold3d/federails-moderation", "source_code_uri" => "https://github.com/manyfold3d/federails-moderation" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["James Smith".freeze]
  s.date = "2025-03-26"
  s.description = "Moderation additions for Federails; reporting, limit/suspend, server blocking, etc".freeze
  s.email = ["james@floppy.org.uk".freeze]
  s.homepage = "https://github.com/manyfold3d/federails-moderation".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new("~> 3.3".freeze)
  s.rubygems_version = "3.6.2".freeze
  s.summary = "Moderation additions for Federails.".freeze

  s.installed_by_version = "3.6.2".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<rails>.freeze, [">= 7.2.2".freeze])
  s.add_runtime_dependency(%q<federails>.freeze, ["~> 0.4".freeze])
  s.add_runtime_dependency(%q<public_suffix>.freeze, ["~> 6.0".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.22".freeze])
end
