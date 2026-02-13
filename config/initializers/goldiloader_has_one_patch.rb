# frozen_string_literal: true
# typed: false

# Patch Goldiloader to accept ActiveRecord 8's force_reload arg in has_one find_target.
# Upstream uses Ruby 2.7 "..." delegation; we reintroduce splat to be safe when prepended order changes.
module Goldiloader
  module SingularAssociationPatch
    def find_target(*args, **kwargs, &block)
      load_with_auto_include { super(*args, **kwargs, &block) }
    end
  end
end
