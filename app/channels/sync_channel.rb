# frozen_string_literal: true

# Yjs synchronization channel using yrb-actioncable gem
class SyncChannel < ApplicationCable::Channel
  include Y::Actioncable::Sync

  # Called when a client subscribes. Expect params like { id: "session-<uuid>" }
  def subscribed
    # Use a namespaced identifier to avoid collisions with other doc types
    doc_id = params[:id].presence || "default"
    sync_for(doc_id)
  end

  # relay incoming CRDT update (already validated by gem)
  def receive(message)
    doc_id = params[:id].presence || "default"
    sync_to(doc_id, message)
  end
end
