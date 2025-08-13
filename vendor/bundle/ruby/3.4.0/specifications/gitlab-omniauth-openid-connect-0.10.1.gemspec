# -*- encoding: utf-8 -*-
# stub: gitlab-omniauth-openid-connect 0.10.1 ruby lib

Gem::Specification.new do |s|
  s.name = "gitlab-omniauth-openid-connect".freeze
  s.version = "0.10.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["John Bohn".freeze, "Ilya Shcherbinin".freeze]
  s.date = "2023-01-24"
  s.description = "OpenID Connect Strategy for OmniAuth.".freeze
  s.email = ["jjbohn@gmail.com".freeze, "m0n9oose@gmail.com".freeze]
  s.homepage = "https://gitlab.com/gitlab-org/gitlab-omniauth-openid-connect".freeze
  s.licenses = ["MIT".freeze]
  s.post_install_message = "############################################################\n#  Deprecation notice for gitlab-omniauth-openid-connect gem\n############################################################\n\nAll changes in this gem are now upstreamed in omniauth_openid_connect\ngem v0.6.0 under the OmniAuth group: https://github.com/omniauth/omniauth_openid_connect.\n\nIn your Gemfile, replace the line:\n\ngem 'gitlab-omniauth-openid-connect', '~> 0.10', require: 'omniauth_openid_connect'\n\nWith:\n\ngem 'omniauth_openid_connect', '~> 0.6'\n\nThe gitlab-omniauth-openid-connect gem is no longer updated.\n".freeze
  s.rubygems_version = "3.4.5".freeze
  s.summary = "OpenID Connect Strategy for OmniAuth".freeze

  s.installed_by_version = "3.6.2".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<addressable>.freeze, ["~> 2.7".freeze])
  s.add_runtime_dependency(%q<omniauth>.freeze, [">= 1.9".freeze, "< 3".freeze])
  s.add_runtime_dependency(%q<openid_connect>.freeze, ["~> 1.2".freeze])
  s.add_development_dependency(%q<faker>.freeze, ["~> 2.17".freeze])
  s.add_development_dependency(%q<guard>.freeze, ["~> 2.14".freeze])
  s.add_development_dependency(%q<guard-bundler>.freeze, ["~> 3.0".freeze])
  s.add_development_dependency(%q<guard-minitest>.freeze, ["~> 2.4".freeze])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.14".freeze])
  s.add_development_dependency(%q<mocha>.freeze, ["~> 1.12".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0".freeze])
  s.add_development_dependency(%q<rubocop>.freeze, ["~> 1.12".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.16".freeze])
end
