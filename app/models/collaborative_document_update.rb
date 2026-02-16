# typed: strict
# frozen_string_literal: true
# shareable_constant_value: literal

class CollaborativeDocumentUpdate < ApplicationRecord
  self.abstract_class = true

  belongs_to :collaborative_document

  validates :seq, presence: true
  validates :ops, presence: true
end
