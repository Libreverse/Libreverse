# frozen_string_literal: true

class SessionFinalization < ApplicationRecord
  validates :session_id, presence: true, uniqueness: true
end
