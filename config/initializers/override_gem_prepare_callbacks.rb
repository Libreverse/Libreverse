# typed: strict
# frozen_string_literal: true
# shareable_constant_value: literal

# Override gem-owned to_prepare callbacks that don't need reload behavior
# This reduces startup time by moving expensive work to one-time after_initialize

# Thredded: move view hooks reset and UserExtender inclusion to after_initialize
Rails.application.config.after_initialize do
  Thredded::AllViewHooks.reset_instance!
  Thredded.user_class&.send(:include, Thredded::UserExtender)
end

# ComfortableMediaSurfer: move decorator loading to after_initialize
Rails.application.config.after_initialize do
  Dir.glob("#{Rails.root}app/decorators/comfortable_media_surfer/*_decorator*.rb").each do |c|
    require_dependency(c)
  end
end

# ReactOnRails: move version check and pool reset to after_initialize
Rails.application.config.after_initialize do
  ReactOnRails::VersionChecker.build.log_if_gem_and_node_package_versions_differ if defined?(ReactOnRails::VersionChecker)
  ReactOnRails::ServerRenderingPool.reset_pool if defined?(ReactOnRails::ServerRenderingPool)
end

# AnyCable: move connection factory setup to after_initialize
Rails.application.config.after_initialize do
  AnyCable.connection_factory = AnyCable::Rails::ConnectionFactory.new if defined?(AnyCable) && AnyCable.respond_to?(:connection_factory=)
end
