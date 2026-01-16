# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

# Apply app-local monkey patches / compatibility shims.
#
# Keep *all* patches in `config/patches/` and load them here so
# `config/initializers/` doesn't become a grab-bag of monkeypatches.

require_relative "../patches/loader"

LibreversePatches.apply(:initializers)
