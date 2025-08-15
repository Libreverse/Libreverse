# frozen_string_literal: true

class CollaborativeDocument < ApplicationRecord
  has_many :collaborative_document_updates, dependent: :destroy

  validates :session_id, presence: true, uniqueness: true

  # Append a Yjs update, auto-incrementing seq
  def append_update!(raw_bytes)
    next_seq = (collaborative_document_updates.maximum(:seq) || 0) + 1
    collaborative_document_updates.create!(seq: next_seq, update: raw_bytes)
  end

  def pending_updates_after(seq)
    collaborative_document_updates.where("seq > ?", seq).order(:seq)
  end
end
