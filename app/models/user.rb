# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

# == Schema Information
#
# Table name: accounts
#
#  id                  :bigint           not null, primary key
#  flags               :integer          default(0), not null
#  password_changed_at :datetime
#  password_hash       :string(255)
#  provider            :string(255)
#  provider_uid        :string(255)
#  status              :integer          default(1), not null
#  username            :string(255)      not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  federated_id        :string(255)
#
# Indexes
#
#  index_accounts_on_federated_id               (federated_id)
#  index_accounts_on_provider_and_provider_uid  (provider,provider_uid) UNIQUE
#  index_accounts_on_username                   (username) UNIQUE
#
class User < ApplicationRecord
  # Thredded requires an ActiveRecord user model
  # This model wraps the Sequel Account model for Thredded compatibility

  self.table_name = "accounts" # Use the same table as Sequel Account

  # Find user by Sequel account
  def self.from_account(account)
    return nil unless account

    find_by(id: account.id)
  end

  # Basic attributes that Thredded expects
  def name
    username || email || "User #{id}"
  end

  def email
    # Get email from the Sequel account
    account = AccountSequel[id]
    account&.email
  end

  def username
    # Get username from the Sequel account
    account = AccountSequel[id]
    account&.username
  end

  # Thredded permission methods
  def thredded_admin?
    account = AccountSequel[id]
    account&.admin? || false
  end

  def thredded_can_read_messageboards
    # Return all messageboards for now - customize as needed
    Thredded::Messageboard.all
  end

  def thredded_can_write_messageboards
    # Return all messageboards for now - customize as needed
    Thredded::Messageboard.all
  end

  def thredded_can_moderate_messageboards
    return Thredded::Messageboard.none unless thredded_admin?

    Thredded::Messageboard.all
  end

  def thredded_can_message_users
    # Return all users for now - customize as needed
    User.all
  end

  # Class methods for Thredded
  def self.thredded_messageboards_readers(_messageboards)
    # Return all users for now - customize as needed
    User.all
  end

  # Override to_param to use id
  def to_param
    id.to_s
  end

  # Thredded user name column
  def self.thredded_user_name_column
    :username
  end

  # Thredded user class
  def self.thredded_user_class
    User
  end
end
