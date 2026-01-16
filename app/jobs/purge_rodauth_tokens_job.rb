# typed: true
# frozen_string_literal: true
# shareable_constant_value: literal

class PurgeRodauthTokensJob < ApplicationJob
  queue_as :maintenance

  # Tables and their deadline columns to clean up.
  EXPIRING_TABLES = {
    account_password_reset_keys: :deadline,
    account_login_change_keys: :deadline,
    account_remember_keys: :deadline
  }.freeze

  def perform
    now = Time.current

    EXPIRING_TABLES.each do |table, deadline_column|
      model = dynamic_model_for(table)
      condition = model.arel_table[deadline_column].lt(now)
      model.where(condition).delete_all
    end
  end

  private

  # Build an anonymous ActiveRecord model for a given table so we can use
  # sanitised query helpers (avoids raw SQL & Brakeman warning).
  def dynamic_model_for(table)
    @models ||= {}
    @models[table] ||= Class.new(ApplicationRecord) do
      self.table_name = table.to_s

      # Give the anonymous class a predictable name for easier debugging
      define_singleton_method(:name) { "Anon#{table.to_s.classify}" }

      # There is no primary key on these Rodauth tables
      self.primary_key = nil
    end
  end
end
