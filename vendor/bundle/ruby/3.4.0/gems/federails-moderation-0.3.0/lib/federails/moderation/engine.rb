require "federails"

module Federails
  module Moderation
    class Engine < ::Rails::Engine
      isolate_namespace Federails::Moderation
    end
  end
end
