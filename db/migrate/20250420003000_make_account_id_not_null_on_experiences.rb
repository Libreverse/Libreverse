# frozen_string_literal: true

class MakeAccountIdNotNullOnExperiences < ActiveRecord::Migration[8.0]
  def up
    # Find or create a guest account without triggering callbacks or role assignment
    guest = Account.unscoped.where(guest: true).first
    unless guest
      now = Time.now.utc.strftime("%Y-%m-%d %H:%M:%S")
      Account.connection.execute <<~SQL
        INSERT INTO accounts (username, password_hash, guest, created_at, updated_at, status)
        VALUES ('guest', '#{SecureRandom.hex(16)}', TRUE, '#{now}', '#{now}', 1)
      SQL
      guest = Account.unscoped.where(guest: true).first
    end

    # rubocop:disable Rails/SkipsModelValidations
    Experience.where(account_id: nil).find_each do |exp|
      exp.update_column(:account_id, guest.id)
    end
    # rubocop:enable Rails/SkipsModelValidations

    change_column_null :experiences, :account_id, false
  end

  def down
    change_column_null :experiences, :account_id, true
  end
end
