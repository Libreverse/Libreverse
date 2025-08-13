# -*- encoding: utf-8 -*-
# stub: audits1984 0.1.7 ruby lib

Gem::Specification.new do |s|
  s.name = "audits1984".freeze
  s.version = "0.1.7".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "https://rubygems.org", "homepage_uri" => "https://github.com/basecamp/audits1984", "source_code_uri" => "https://github.com/basecamp/audits1984" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jorge Manrubia".freeze]
  s.date = "2024-07-17"
  s.description = "Rails engine that implements a simple auditing tool for console1984 sessions".freeze
  s.email = ["jorge.manrubia@gmail.com".freeze]
  s.homepage = "https://github.com/basecamp/audits1984".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.5.11".freeze
  s.summary = "A simple auditing tool for console1984".freeze

  s.installed_by_version = "3.6.2".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<rouge>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<turbo-rails>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<rinku>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<console1984>.freeze, [">= 0".freeze])
end
