# typed: true
# frozen_string_literal: true

# This shim provides a module to fix the ActiveRecord RBI issue
# where it tries to extend Method (a class) instead of a module

module MethodModule
end
