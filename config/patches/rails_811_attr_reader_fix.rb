# frozen_string_literal: true
# shareable_constant_value: literal

# Patch for Rails 8.1.1 attr_reader issue with modules
# This fixes the "protected method `attr_reader' called for module" error
# that occurs when Sidekiq boots Rails 8.1.1

require "active_support/core_ext/module/attr_internal"
require "active_support/core_ext/module/redefine_method"

module LibreverseModuleRedefineMethodCompat
  def redefine_method(sym, aka = nil, &blk)
    alias_method(aka, sym) if aka && (method_defined?(sym) || private_method_defined?(sym) || protected_method_defined?(sym))

    visibility = method_visibility(sym)
    silence_redefinition_of_method(sym)
    define_method(sym, &blk)
    __send__(visibility, sym)
  end
end

Module.prepend(LibreverseModuleRedefineMethodCompat)

module LibreverseArrayEachPairCompat
  def each_pair
    return enum_for(:each_pair) unless block_given?

    each_with_index { |e, i| yield(i, e) }
  end
end

Array.prepend(LibreverseArrayEachPairCompat)

module LibreverseClassDescendantsCompat
  def descendants(*)
    subclasses = self.subclasses
    subclasses.concat(subclasses.flat_map(&:descendants))
  end
end

Class.prepend(LibreverseClassDescendantsCompat)

class Module
  def redefine_singleton_method(method, &block)
    singleton_class.__send__(:redefine_method, method, &block)
  end

  private

  def attr_internal_define(attr_name, type)
    internal_name = Module.attr_internal_naming_format % attr_name
    __send__("attr_#{type}", internal_name)
    if type == :writer
      attr_name = "#{attr_name}="
      internal_name = "#{internal_name}="
    end
    alias_method attr_name, internal_name
    remove_method internal_name
  end
end
