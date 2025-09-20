# frozen_string_literal: true
# Compatibility shim: some gems (e.g., older Thredded templates) may call
# `Rails.application.assets.load_path`, but Sprockets 4 exposes `paths` instead.
# Provide a minimal `load_path` delegating to `paths` when missing.
if defined?(Rails) && Rails.application.respond_to?(:assets) && Rails.application.assets &&
   Rails.application.assets.respond_to?(:paths) && !Rails.application.assets.respond_to?(:load_path)
  Rails.logger.info "[sprockets_compat] Defining Sprockets::Environment#load_path shim" rescue nil
  module Sprockets
    class Environment
      def load_path
        paths
      end unless method_defined?(:load_path)
    end
  end
end
