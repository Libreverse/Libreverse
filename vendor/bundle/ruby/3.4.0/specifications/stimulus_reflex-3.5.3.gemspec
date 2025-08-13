# -*- encoding: utf-8 -*-
# stub: stimulus_reflex 3.5.3 ruby lib

Gem::Specification.new do |s|
  s.name = "stimulus_reflex".freeze
  s.version = "3.5.3".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/stimulusreflex/stimulus_reflex/issues", "changelog_uri" => "https://github.com/stimulusreflex/stimulus_reflex/CHANGELOG.md", "documentation_uri" => "https://docs.stimulusreflex.com", "homepage_uri" => "https://github.com/stimulusreflex/stimulus_reflex", "source_code_uri" => "https://github.com/stimulusreflex/stimulus_reflex" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Nathan Hopkins".freeze]
  s.date = "2024-12-15"
  s.email = ["natehop@gmail.com".freeze]
  s.homepage = "https://github.com/stimulusreflex/stimulus_reflex".freeze
  s.licenses = ["MIT".freeze]
  s.post_install_message = "Finish installation by running:\n\nrake stimulus_reflex:install\n\nGet support for StimulusReflex and CableReady on Discord:\n\nhttps://discord.gg/stimulus-reflex\n\n".freeze
  s.required_ruby_version = Gem::Requirement.new(">= 3.0.0".freeze)
  s.rubygems_version = "3.5.22".freeze
  s.summary = "Build reactive applications with the Rails tooling you already know and love.".freeze

  s.installed_by_version = "3.6.2".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<actioncable>.freeze, [">= 5.2".freeze])
  s.add_runtime_dependency(%q<actionpack>.freeze, [">= 5.2".freeze])
  s.add_runtime_dependency(%q<actionview>.freeze, [">= 5.2".freeze])
  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 5.2".freeze])
  s.add_runtime_dependency(%q<railties>.freeze, [">= 5.2".freeze])
  s.add_runtime_dependency(%q<cable_ready>.freeze, ["~> 5.0".freeze])
  s.add_runtime_dependency(%q<nokogiri>.freeze, ["~> 1.0".freeze])
  s.add_runtime_dependency(%q<rack>.freeze, [">= 2".freeze, "< 4".freeze])
  s.add_runtime_dependency(%q<redis>.freeze, [">= 4.0".freeze, "< 6.0".freeze])
  s.add_runtime_dependency(%q<nokogiri-html5-inference>.freeze, ["~> 0.3".freeze])
  s.add_development_dependency(%q<bundler>.freeze, ["~> 2.0".freeze])
  s.add_development_dependency(%q<magic_frozen_string_literal>.freeze, ["~> 1.2".freeze])
  s.add_development_dependency(%q<mocha>.freeze, ["~> 1.13".freeze])
  s.add_development_dependency(%q<rails>.freeze, [">= 5.2".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0".freeze])
  s.add_development_dependency(%q<standard>.freeze, ["~> 1.24".freeze])
  s.add_development_dependency(%q<minitest>.freeze, ["= 5.18.1".freeze])
end
