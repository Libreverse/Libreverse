require "federails/moderation/version"
require "federails/moderation/engine"
require "federails/moderation/configuration"

module Federails
  module Moderation
    mattr_reader :configuration
    @@configuration = Configuration

    def self.configure
      yield @@configuration
    end

    def self.table_name_prefix
      "federails_moderation_"
    end
  end
end
