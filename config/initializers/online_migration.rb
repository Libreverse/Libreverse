# typed: true
# frozen_string_literal: true
# shareable_constant_value: literal

require "online_migration"

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Migration.include(OnlineMigration)
end
