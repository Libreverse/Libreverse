# frozen_string_literal: true

class CollaborativeDocumentUpdate < ApplicationRecord
  belongs_to :collaborative_document

  validates :seq, presence: true
  validates :update, presence: true
end
