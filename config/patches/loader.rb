# frozen_string_literal: true
# shareable_constant_value: literal

# Central place for app-local monkey patches / compatibility shims.
#
# Why this exists:
# - Keep `config/application.rb` readable
# - Make it obvious what is being patched and why
# - Ensure patches are applied in the right boot phase
#
# Boot phases:
# - :pre_bundler  -> after `require "rails/all"`, before `Bundler.require`
# - :post_bundler -> immediately after `Bundler.require`, but before
#                   `Rails.application.initialize!`
#
module LibreversePatches
  module_function

  def apply(stage)
    patch_files_for(stage).each do |relative|
      require_relative(relative)
    end
  end

  def patch_files_for(stage)
    case stage
    when :initializers
      [
        # TruffleRuby runtime compatibility
        "truffleruby_fiber_local_storage",

        # Debugging aids
        "initializer_trace",

        # Compatibility patches
        "react_on_rails_connection_pool",
        "connection_pool_initialize_compat",
        "connection_pool_with_compat",
        "sprockets_compat",
        "inline_svg_patch",
        "routing_patch",
        "tidb_transient_retry",

        # Test-only shims
        "vite_test_fallback",
        "test_trilogy_patches",
      ]
    else
      raise ArgumentError, "Unknown patch stage: #{stage.inspect}"
    end
  end
end
