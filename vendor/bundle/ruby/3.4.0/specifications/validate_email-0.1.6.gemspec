# -*- encoding: utf-8 -*-
# stub: validate_email 0.1.6 ruby lib

Gem::Specification.new do |s|
  s.name = "validate_email".freeze
  s.version = "0.1.6".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Tanel Suurhans".freeze, "Tarmo Lehtpuu".freeze]
  s.date = "2012-07-12"
  s.description = "Library for validating email addresses in Rails 3 models.".freeze
  s.email = ["tanel.suurhans@perfectline.ee".freeze, "tarmo.lehtpuu@perfectline.ee".freeze]
  s.extra_rdoc_files = ["README.markdown".freeze]
  s.files = ["README.markdown".freeze]
  s.homepage = "http://github.com/perfectline/validates_email/tree/master".freeze
  s.rubygems_version = "1.8.24".freeze
  s.summary = "Library for validating email addresses in Rails 3 models.".freeze

  s.installed_by_version = "3.6.2".freeze

  s.specification_version = 3

  s.add_development_dependency(%q<rspec>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<diff-lcs>.freeze, [">= 1.1.2".freeze])
  s.add_development_dependency(%q<active_record>.freeze, [">= 3.0.0".freeze])
  s.add_development_dependency(%q<sqlite3-ruby>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<mail>.freeze, [">= 2.2.5".freeze])
  s.add_runtime_dependency(%q<activemodel>.freeze, [">= 3.0".freeze])
end
