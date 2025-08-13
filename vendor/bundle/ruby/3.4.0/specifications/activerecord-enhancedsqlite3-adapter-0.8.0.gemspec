# -*- encoding: utf-8 -*-
# stub: activerecord-enhancedsqlite3-adapter 0.8.0 ruby lib

Gem::Specification.new do |s|
  s.name = "activerecord-enhancedsqlite3-adapter".freeze
  s.version = "0.8.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "https://rubygems.org", "changelog_uri" => "https://github.com/fractaledmind/activerecord-enhancedsqlite3-adapter/CHANGELOG.md", "homepage_uri" => "https://github.com/fractaledmind/activerecord-enhancedsqlite3-adapter", "source_code_uri" => "https://github.com/fractaledmind/activerecord-enhancedsqlite3-adapter" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Stephen Margheim".freeze]
  s.bindir = "exe".freeze
  s.date = "2024-05-05"
  s.description = "Back-ports generated column support, deferred foreign key support, custom foreign key support, improved default configuration, and adds support for pragma tuning and extension loading".freeze
  s.email = ["stephen.margheim@gmail.com".freeze]
  s.homepage = "https://github.com/fractaledmind/activerecord-enhancedsqlite3-adapter".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.6.0".freeze)
  s.rubygems_version = "3.5.1".freeze
  s.summary = "ActiveRecord adapter for SQLite that enhances the default.".freeze

  s.installed_by_version = "3.6.2".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<activerecord>.freeze, [">= 7.1".freeze])
  s.add_runtime_dependency(%q<sqlite3>.freeze, [">= 1.6".freeze])
  s.add_development_dependency(%q<combustion>.freeze, ["~> 1.3".freeze])
  s.add_development_dependency(%q<railties>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<minitest>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
end
