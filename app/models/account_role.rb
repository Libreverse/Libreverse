# typed: strict
# frozen_string_literal: true
# shareable_constant_value: literal

# == Schema Information
#
# Table name: account_roles
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#  role_id    :bigint           not null
#
# Indexes
#
#  index_account_roles_on_account_id_and_role_id  (account_id,role_id) UNIQUE
#  index_account_roles_on_role_id                 (role_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (role_id => roles.id)
#
class AccountRole < ApplicationRecord
  belongs_to :account
  belongs_to :role
end
