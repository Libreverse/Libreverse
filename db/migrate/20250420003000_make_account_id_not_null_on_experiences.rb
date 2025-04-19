# frozen_string_literal: true

class MakeAccountIdNotNullOnExperiences < ActiveRecord::Migration[8.0]
  def up
    guest = Account.find_or_create_by!(guest: true) do |a|
      a.username = "guest"
      a.password = SecureRandom.hex(16)
    end

    # fasterer:disable ForEach
    Experience.where(account_id: nil).find_each do |exp|
      exp.update!(account_id: guest.id)
    end
    # fasterer:enable ForEach

    change_column_null :experiences, :account_id, false
  end

  def down
    change_column_null :experiences, :account_id, true
  end
end
