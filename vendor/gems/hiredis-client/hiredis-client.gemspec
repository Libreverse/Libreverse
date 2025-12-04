# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "hiredis-client"
  spec.version = "0.26.1"
  spec.authors = ["Jean Boussier"]
  spec.email = ["jean.boussier@gmail.com"]

  spec.summary = "Hiredis binding for redis-client (vendored with TruffleRuby support)"
  spec.homepage = "https://github.com/redis-rb/redis-client"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = File.join(spec.homepage, "blob/master/CHANGELOG.md")

  spec.files = Dir.glob("{ext,lib}/**/*") + ["README.md"]
  spec.require_paths = ["lib", "ext/redis_client/hiredis"]
  spec.extensions = ["ext/redis_client/hiredis/extconf.rb"]

  spec.add_dependency "redis-client", "= 0.26.1"
end
