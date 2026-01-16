# typed: true
# frozen_string_literal: true
# shareable_constant_value: literal

# Compatibility shim: some gems (e.g., older Thredded templates) may call
# `Rails.application.assets.load_path`, but Sprockets 4 exposes `paths` instead.
# Provide a minimal `load_path` delegating to `paths` when missing.
if defined?(Rails) && Rails.application.respond_to?(:assets) && Rails.application.assets.respond_to?(:paths) && !Rails.application.assets.respond_to?(:load_path)
  begin
    Rails.logger.info "[sprockets_compat] Defining Sprockets::Environment#load_path shim"
  rescue StandardError
    nil
  end

  module Sprockets
    class Environment
      unless method_defined?(:load_path)
        def load_path
          paths
        end
      end
    end
  end
end
