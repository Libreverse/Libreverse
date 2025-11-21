# frozen_string_literal: true
# shareable_constant_value: literal

class SessionFinalization < ApplicationRecord
  validates :session_id, presence: true, uniqueness: true

  after_initialize do
    self.transient_state ||= {}
    self.yjs_vector ||= {}
  end

  before_validation do
    self.transient_state = {} if transient_state.nil?
    self.yjs_vector = {} if yjs_vector.nil?
  end
end
