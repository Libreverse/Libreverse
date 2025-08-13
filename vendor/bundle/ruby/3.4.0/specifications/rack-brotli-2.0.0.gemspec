# -*- encoding: utf-8 -*-
# stub: rack-brotli 2.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "rack-brotli".freeze
  s.version = "2.0.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Marco Costa".freeze]
  s.date = "2024-06-07"
  s.description = "Rack::Brotli enables Google's Brotli compression on HTTP responses".freeze
  s.email = "marco@marcotc.com".freeze
  s.extra_rdoc_files = ["README.md".freeze, "COPYING".freeze]
  s.files = ["COPYING".freeze, "README.md".freeze]
  s.homepage = "http://github.com/marcotc/rack-brotli/".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--line-numbers".freeze, "--inline-source".freeze, "--title".freeze, "rack-brotli".freeze, "--main".freeze, "README".freeze]
  s.rubygems_version = "3.3.7".freeze
  s.summary = "Brotli compression for Rack responses".freeze

  s.installed_by_version = "3.6.2".freeze

  s.specification_version = 2

  s.add_runtime_dependency(%q<rack>.freeze, [">= 3".freeze])
  s.add_runtime_dependency(%q<brotli>.freeze, [">= 0.3".freeze])
end
