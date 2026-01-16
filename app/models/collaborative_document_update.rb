# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

class CollaborativeDocumentUpdate < ApplicationRecord
  belongs_to :collaborative_document

  validates :seq, presence: true
  validates :ops, presence: true
end
