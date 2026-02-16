# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

class CleanupRemainingRedundantIndexes < ActiveRecord::Migration[8.1]
  def change
    # These indexes are named like foreign keys but are plain indexes on primary keys.
    remove_idx(:account_login_change_keys, :fk_rails_18962144a4)
    remove_idx(:account_password_reset_keys, :fk_rails_ccaeb37cea)
    remove_idx(:account_remember_keys, :fk_rails_9b2f6d8501)
    remove_idx(:account_session_keys, :fk_rails_86a43d3592)
    remove_idx(:account_verification_keys, :fk_rails_2e3b612008)

    # Keep FK support indexes while dropping AR Doctor-reported redundant composites.
    add_index :oauth_pushed_requests, :oauth_application_id, name: :idx_oauth_pushed_requests_on_oauth_application_id unless index_exists?(:oauth_pushed_requests, :oauth_application_id, name: :idx_oauth_pushed_requests_on_oauth_application_id)
    remove_idx(:oauth_pushed_requests, :index_oauth_pushed_requests_on_oauth_application_id_and_code)

    add_index :account_active_session_keys, :account_id, name: :idx_account_active_session_keys_on_account_id unless index_exists?(:account_active_session_keys, :account_id, name: :idx_account_active_session_keys_on_account_id)
    remove_idx(:account_active_session_keys, :index_account_active_session_keys_on_account_id_and_session_id)
  end

  private

  def remove_idx(table, index_name)
    return unless index_exists?(table, name: index_name)

    remove_index(table, name: index_name)
  rescue ActiveRecord::StatementInvalid => e
    Rails.logger.info("Skipping index #{index_name} on #{table}: #{e.message}")
  end
end
