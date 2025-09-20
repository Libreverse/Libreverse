# frozen_string_literal: true

require "test_helper"

class AccountInterfaceTest < ActiveSupport::TestCase
  test "AccountSequel implements effective_user? consistent with Account" do
    ar = Account.new(username: "interfacetest", status: 2, guest: false)
    seq = AccountSequel.new(username: "interfacetest", status: 2, guest: false)
    assert_equal ar.effective_user?, seq.effective_user?, "effective_user? should align"
    seq.guest = true
    ar.guest = true
    assert_equal ar.effective_user?, seq.effective_user?, "effective_user? should reflect guest state"
  end
end
