# frozen_string_literal: true
# shareable_constant_value: literal

# Yjs synchronization channel using yrb-actioncable gem
class SyncChannel < ApplicationCable::Channel
  # include Y::Actioncable::Sync  # TODO: Fix when proper gem is available

  # Called when a client subscribes. Expect params like { id: "session-<uuid>" }
  def subscribed
    raw_id = params[:id].to_s
    validate_raw_id!(raw_id)

    # Ensure the connected account is authorized to access this document
    reject unless authorized_for_doc?(raw_id)

    # Cache a namespaced key to avoid collisions with other doc types
    @doc_key = namespaced_key_for(raw_id)
    sync_for(@doc_key)
  end

  # relay incoming CRDT update (already validated by gem)
  def receive(message)
    return unless @doc_key # only proceed if subscription succeeded

    sync_to(@doc_key, message)
  end

  private

  # Accept only conservative ids to prevent cache/key abuse
  # Allowed: letters, numbers, dashes, underscores and colons. Max 100 chars.
  def validate_raw_id!(raw_id)
    raise ArgumentError, "blank id" if raw_id.blank?
    return if raw_id.length <= 100 && raw_id.match?(/\A[\w:-]+\z/)

      raise ArgumentError, "invalid id"
  end

  def namespaced_key_for(raw_id)
    "doc:#{raw_id}"
  end

  def authorized_for_doc?(raw_id)
    # Example doc id format coming from multiplayer experiences: "exp_<experience_id>_<random>"
    if (m = raw_id.match(/\Aexp_(\d+)_/))
      exp_id = m[1].to_i
      experience = Experience.find_by(id: exp_id)
      return false unless experience

      account = current_ar_account
      return false unless account

      # Permit if approved (public), owner, or admin
      experience.approved? || experience.account_id == account.id || account.admin?
    else
      # For unknown doc namespaces, be conservative: allow only admins
      current_ar_account&.admin? || false
    end
  rescue StandardError => e
    Rails.logger.warn "[SyncChannel] Authorization error for id=#{raw_id.inspect}: #{e.message}"
    false
  end

  def current_ar_account
    @current_ar_account ||= Account.find_by(id: connection.current_account_id)
  end
end
