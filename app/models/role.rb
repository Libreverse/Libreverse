# frozen_string_literal: true

class Role < ApplicationRecord
  has_many :account_roles, dependent: :destroy
  has_many :accounts, through: :account_roles

  belongs_to :resource,
             polymorphic: true,
             optional: true

  validates :resource_type,
            inclusion: { in: Rolify.resource_types },
            allow_nil: true

  scopify
end
