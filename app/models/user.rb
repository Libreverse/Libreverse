# frozen_string_literal: true

class User < ApplicationRecord
  # Thredded requires an ActiveRecord user model
  # This model wraps the Sequel Account model for Thredded compatibility

  self.table_name = 'accounts' # Use the same table as Sequel Account

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
  def self.thredded_messageboards_readers(messageboards)
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