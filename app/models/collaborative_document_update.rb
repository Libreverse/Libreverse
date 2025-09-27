class CollaborativeDocumentUpdate < ApplicationRecord
  belongs_to :collaborative_document

  validates :seq, presence: true
  validates :ops, presence: true
end
