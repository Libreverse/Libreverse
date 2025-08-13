# -*- encoding: utf-8 -*-
# stub: nokogiri-html5-inference 0.3.0 ruby lib

Gem::Specification.new do |s|
  s.name = "nokogiri-html5-inference".freeze
  s.version = "0.3.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/flavorjones/nokogiri-html5-inference/issues", "changelog_uri" => "https://github.com/flavorjones/nokogiri-html5-inference/blob/main/CHANGELOG.md", "homepage_uri" => "https://github.com/flavorjones/nokogiri-html5-inference", "source_code_uri" => "https://github.com/flavorjones/nokogiri-html5-inference" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Mike Dalessio".freeze]
  s.date = "2024-05-05"
  s.description = "Infer from the HTML5 input whether it's a fragment or a document, and if it's a fragment what\nthe proper context node should be. This is useful for parsing trusted content like view\nsnippets, particularly for morphing cases like StimulusReflex.\n".freeze
  s.email = ["mike.dalessio@gmail.com".freeze]
  s.homepage = "https://github.com/flavorjones/nokogiri-html5-inference".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.0.0".freeze)
  s.rubygems_version = "3.5.9".freeze
  s.summary = "Given HTML5 input, make a reasonable guess at how to parse it correctly.".freeze

  s.installed_by_version = "3.6.2".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<nokogiri>.freeze, ["~> 1.14".freeze])
end
