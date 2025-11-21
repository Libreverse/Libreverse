# frozen_string_literal: true
# shareable_constant_value: literal

class AccountRole < ApplicationRecord
  belongs_to :account
  belongs_to :role
end
