# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

class CollaborativeDocument < ApplicationRecord
  self.abstract_class = true

  has_many :collaborative_document_updates, dependent: :destroy

  validates :session_id, presence: true, uniqueness: true

  after_initialize do
    # Provide in-Ruby defaults since MySQL/TiDB disallow defaults on BLOB/JSON.
    self.base_snapshot ||= "".b
    self.version_vector ||= {}
  end

  before_validation do
    self.base_snapshot = "".b if base_snapshot.nil?
    self.version_vector = {} if version_vector.nil?
  end

  # Append a Yjs update, auto-incrementing seq
  def append_update!(raw_bytes)
    next_seq = (collaborative_document_updates.maximum(:seq) || 0) + 1
    # Use the `ops` alias for the `update` column to avoid colliding with AR#update
    collaborative_document_updates.create!(seq: next_seq, ops: raw_bytes)
  end

  def pending_updates_after(seq)
    collaborative_document_updates.where("seq > ?", seq).order(:seq)
  end
end
