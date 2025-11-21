# frozen_string_literal: true
# shareable_constant_value: literal

require "test_helper"

class AccountCreationModerationTest < ActiveSupport::TestCase
  test "AccountSequel should reject inappropriate usernames" do
    sequel_account = AccountSequel.new(username: "fuckinguser", status: 2)
    assert_not sequel_account.valid?, "AccountSequel should reject inappropriate username"
  end

  test "AccountSequel should allow valid usernames" do
    sequel_account = AccountSequel.new(username: "validuser123", status: 2)
    assert sequel_account.valid?, "AccountSequel should allow valid username"
  end
end
