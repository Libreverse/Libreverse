# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

require "test_helper"

class AccountInterfaceTest < ActiveSupport::TestCase
  test "AccountSequel implements effective_user? consistent with Account" do
    ar = Account.new(username: "interfacetest", status: 2, flags: 0)
    seq = AccountSequel.new(username: "interfacetest", status: 2, flags: 0)
    assert_equal ar.effective_user?, seq.effective_user?, "effective_user? should align"
    seq.flags |= 2  # Set guest flag (bit position 2)
    ar.flags |= 2   # Set guest flag (bit position 2)
    assert_equal ar.effective_user?, seq.effective_user?, "effective_user? should reflect guest state"
  end
end
