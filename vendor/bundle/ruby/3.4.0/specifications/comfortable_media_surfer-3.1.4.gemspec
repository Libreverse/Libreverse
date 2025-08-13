# -*- encoding: utf-8 -*-
# stub: comfortable_media_surfer 3.1.4 ruby lib

Gem::Specification.new do |s|
  s.name = "comfortable_media_surfer".freeze
  s.version = "3.1.4".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Oleg Khabarov".freeze, "Andrew vonderLuft".freeze, "ShakaCode".freeze]
  s.date = "1980-01-02"
  s.description = "ComfortableMediaSurfer is a powerful Rails 7.0+ CMS Engine".freeze
  s.email = ["justin@shakacode.com".freeze]
  s.homepage = "https://github.com/shakacode/comfortable-media-surfer".freeze
  s.licenses = ["MIT".freeze]
  s.post_install_message = "Please run rake comfy:compile_assets to compile assets.".freeze
  s.required_ruby_version = Gem::Requirement.new(">= 3.2.0".freeze)
  s.rubygems_version = "3.6.9".freeze
  s.summary = "Rails 7.0+ CMS Engine".freeze

  s.installed_by_version = "3.6.2".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<active_link_to>.freeze, ["~> 1.0".freeze, ">= 1.0.5".freeze])
  s.add_runtime_dependency(%q<comfy_bootstrap_form>.freeze, ["~> 4.0".freeze, ">= 4.0.0".freeze])
  s.add_runtime_dependency(%q<haml-rails>.freeze, ["~> 2.1".freeze, ">= 2.1.0".freeze])
  s.add_runtime_dependency(%q<image_processing>.freeze, ["~> 1.2".freeze, ">= 1.12.2".freeze])
  s.add_runtime_dependency(%q<kaminari>.freeze, ["~> 1.2".freeze, ">= 1.2.2".freeze])
  s.add_runtime_dependency(%q<kramdown>.freeze, ["~> 2.4".freeze, ">= 2.4.0".freeze])
  s.add_runtime_dependency(%q<mimemagic>.freeze, ["~> 0.4".freeze, ">= 0.4.3".freeze])
  s.add_runtime_dependency(%q<mini_magick>.freeze, [">= 4.12".freeze, "< 6.0".freeze])
  s.add_runtime_dependency(%q<rails>.freeze, [">= 7.0.0".freeze])
  s.add_runtime_dependency(%q<rails-i18n>.freeze, [">= 6.0.0".freeze])
  s.add_runtime_dependency(%q<sassc-rails>.freeze, [">= 2.1.2".freeze])
end
