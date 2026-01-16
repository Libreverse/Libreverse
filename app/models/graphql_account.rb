# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

class GraphqlAccount
  include ActiveAttr::Attributes
  include ActiveAttr::BlockInitialization
  include GraphqlRails::Model

  graphql do |c|
    c.attribute(:id, type: "ID!")
    c.attribute(:username, type: "String!")
    c.attribute(:admin, type: "Boolean!")
    c.attribute(:guest, type: "Boolean!")
    c.attribute(:status, type: "String!")
  end

  attribute :id
  attribute :username
  attribute :admin
  attribute :guest
  attribute :status

  def initialize(account)
    super(
      id: account.id,
      username: account.username,
      admin: account.admin?,
      guest: account.guest?,
      status: account_status_string(account.status)
    )
  end

  private

  def account_status_string(status)
    case status
    when 1 then "unverified"
    when 2 then "verified"
    when 3 then "closed"
    else "unknown"
    end
  end
end
