# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

class RemoveRedundantForeignKeysPart1 < ActiveRecord::Migration[8.1]
  def change
    remove_fk(:account_login_change_keys, :fk_rails_18962144a4)
    remove_fk(:account_password_reset_keys, :fk_rails_ccaeb37cea)
    remove_fk(:account_remember_keys, :fk_rails_9b2f6d8501)
    remove_fk(:account_session_keys, :fk_rails_86a43d3592)
    remove_fk(:account_verification_keys, :fk_rails_2e3b612008)
  end

  private

  def remove_fk(from_table, fk_name)
    return unless foreign_key_exists?(from_table, name: fk_name)

    remove_foreign_key(from_table, name: fk_name)
  end
end
