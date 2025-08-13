# -*- encoding: utf-8 -*-
# stub: rodauth-oauth 1.6.3 ruby lib

Gem::Specification.new do |s|
  s.name = "rodauth-oauth".freeze
  s.version = "1.6.3".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://gitlab.com/os85/rodauth-oauth/issues", "changelog_uri" => "https://gitlab.com/os85/rodauth-oauth/-/blob/master/CHANGELOG.md", "documentation_uri" => "https://os85.gitlab.io/rodauth-oauth/rdoc/", "homepage_uri" => "https://os85.gitlab.io/rodauth-oauth/", "rubygems_mfa_required" => "true", "source_code_uri" => "https://gitlab.com/os85/rodauth-oauth" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Tiago Cardoso".freeze]
  s.date = "2024-07-26"
  s.description = "Implementation of the OAuth 2.0 protocol on top of rodauth.".freeze
  s.email = ["cardoso_tiago@hotmail.com".freeze]
  s.extra_rdoc_files = ["LICENSE.txt".freeze, "README.md".freeze, "MIGRATION-GUIDE-v1.md".freeze, "CHANGELOG.md".freeze, "doc/release_notes/0_0_1.md".freeze, "doc/release_notes/0_0_2.md".freeze, "doc/release_notes/0_0_3.md".freeze, "doc/release_notes/0_0_4.md".freeze, "doc/release_notes/0_0_5.md".freeze, "doc/release_notes/0_0_6.md".freeze, "doc/release_notes/0_10_0.md".freeze, "doc/release_notes/0_10_1.md".freeze, "doc/release_notes/0_10_2.md".freeze, "doc/release_notes/0_10_3.md".freeze, "doc/release_notes/0_10_4.md".freeze, "doc/release_notes/0_1_0.md".freeze, "doc/release_notes/0_2_0.md".freeze, "doc/release_notes/0_3_0.md".freeze, "doc/release_notes/0_4_0.md".freeze, "doc/release_notes/0_4_1.md".freeze, "doc/release_notes/0_4_2.md".freeze, "doc/release_notes/0_4_3.md".freeze, "doc/release_notes/0_5_0.md".freeze, "doc/release_notes/0_5_1.md".freeze, "doc/release_notes/0_6_0.md".freeze, "doc/release_notes/0_6_1.md".freeze, "doc/release_notes/0_7_0.md".freeze, "doc/release_notes/0_7_1.md".freeze, "doc/release_notes/0_7_2.md".freeze, "doc/release_notes/0_7_3.md".freeze, "doc/release_notes/0_7_4.md".freeze, "doc/release_notes/0_8_0.md".freeze, "doc/release_notes/0_9_0.md".freeze, "doc/release_notes/0_9_1.md".freeze, "doc/release_notes/0_9_2.md".freeze, "doc/release_notes/0_9_3.md".freeze, "doc/release_notes/1_0_0.md".freeze, "doc/release_notes/1_1_0.md".freeze, "doc/release_notes/1_2_0.md".freeze, "doc/release_notes/1_3_0.md".freeze, "doc/release_notes/1_3_1.md".freeze, "doc/release_notes/1_3_2.md".freeze, "doc/release_notes/1_4_0.md".freeze, "doc/release_notes/1_5_0.md".freeze, "doc/release_notes/1_6_0.md".freeze, "doc/release_notes/1_6_1.md".freeze, "doc/release_notes/1_6_2.md".freeze, "doc/release_notes/1_6_3.md".freeze]
  s.files = ["CHANGELOG.md".freeze, "LICENSE.txt".freeze, "MIGRATION-GUIDE-v1.md".freeze, "README.md".freeze, "doc/release_notes/0_0_1.md".freeze, "doc/release_notes/0_0_2.md".freeze, "doc/release_notes/0_0_3.md".freeze, "doc/release_notes/0_0_4.md".freeze, "doc/release_notes/0_0_5.md".freeze, "doc/release_notes/0_0_6.md".freeze, "doc/release_notes/0_10_0.md".freeze, "doc/release_notes/0_10_1.md".freeze, "doc/release_notes/0_10_2.md".freeze, "doc/release_notes/0_10_3.md".freeze, "doc/release_notes/0_10_4.md".freeze, "doc/release_notes/0_1_0.md".freeze, "doc/release_notes/0_2_0.md".freeze, "doc/release_notes/0_3_0.md".freeze, "doc/release_notes/0_4_0.md".freeze, "doc/release_notes/0_4_1.md".freeze, "doc/release_notes/0_4_2.md".freeze, "doc/release_notes/0_4_3.md".freeze, "doc/release_notes/0_5_0.md".freeze, "doc/release_notes/0_5_1.md".freeze, "doc/release_notes/0_6_0.md".freeze, "doc/release_notes/0_6_1.md".freeze, "doc/release_notes/0_7_0.md".freeze, "doc/release_notes/0_7_1.md".freeze, "doc/release_notes/0_7_2.md".freeze, "doc/release_notes/0_7_3.md".freeze, "doc/release_notes/0_7_4.md".freeze, "doc/release_notes/0_8_0.md".freeze, "doc/release_notes/0_9_0.md".freeze, "doc/release_notes/0_9_1.md".freeze, "doc/release_notes/0_9_2.md".freeze, "doc/release_notes/0_9_3.md".freeze, "doc/release_notes/1_0_0.md".freeze, "doc/release_notes/1_1_0.md".freeze, "doc/release_notes/1_2_0.md".freeze, "doc/release_notes/1_3_0.md".freeze, "doc/release_notes/1_3_1.md".freeze, "doc/release_notes/1_3_2.md".freeze, "doc/release_notes/1_4_0.md".freeze, "doc/release_notes/1_5_0.md".freeze, "doc/release_notes/1_6_0.md".freeze, "doc/release_notes/1_6_1.md".freeze, "doc/release_notes/1_6_2.md".freeze, "doc/release_notes/1_6_3.md".freeze]
  s.homepage = "https://gitlab.com/os85/rodauth-oauth".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5.0".freeze)
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Implementation of the OAuth 2.0 protocol on top of rodauth.".freeze

  s.installed_by_version = "3.6.2".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<base64>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<rodauth>.freeze, ["~> 2.0".freeze])
end
