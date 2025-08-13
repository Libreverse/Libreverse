# -*- encoding: utf-8 -*-
# stub: fasterer 0.11.0 ruby lib

Gem::Specification.new do |s|
  s.name = "fasterer".freeze
  s.version = "0.11.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Damir Svrtan".freeze]
  s.date = "2023-11-20"
  s.description = "Use Fasterer to check various places in your code that could be faster.".freeze
  s.email = ["damir.svrtan@gmail.com".freeze]
  s.executables = ["fasterer".freeze]
  s.files = ["bin/fasterer".freeze]
  s.homepage = "https://github.com/DamirSvrtan/fasterer".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3".freeze)
  s.rubygems_version = "2.7.6.2".freeze
  s.summary = "Run Ruby more than fast. Fasterer".freeze

  s.installed_by_version = "3.6.2".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<ruby_parser>.freeze, [">= 3.19.1".freeze])
  s.add_development_dependency(%q<bundler>.freeze, [">= 1.6".freeze])
  s.add_development_dependency(%q<pry>.freeze, ["~> 0.10".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 12.3.3".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.2".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.9".freeze])
end
