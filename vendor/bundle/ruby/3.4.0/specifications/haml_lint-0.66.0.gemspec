# -*- encoding: utf-8 -*-
# stub: haml_lint 0.66.0 ruby lib

Gem::Specification.new do |s|
  s.name = "haml_lint".freeze
  s.version = "0.66.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Shane da Silva".freeze]
  s.date = "2025-08-03"
  s.description = "Configurable tool for writing clean and consistent HAML".freeze
  s.email = ["shane@dasilva.io".freeze]
  s.executables = ["haml-lint".freeze]
  s.files = ["bin/haml-lint".freeze]
  s.homepage = "https://github.com/sds/haml-lint".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.0".freeze)
  s.rubygems_version = "3.6.2".freeze
  s.summary = "HAML lint tool".freeze

  s.installed_by_version = "3.6.2".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<haml>.freeze, [">= 5.0".freeze])
  s.add_runtime_dependency(%q<parallel>.freeze, ["~> 1.10".freeze])
  s.add_runtime_dependency(%q<rainbow>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<rubocop>.freeze, [">= 1.0".freeze])
  s.add_runtime_dependency(%q<sysexits>.freeze, ["~> 1.1".freeze])
end
