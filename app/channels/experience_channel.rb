# frozen_string_literal: true
# shareable_constant_value: literal

class ExperienceChannel < ApplicationCable::Channel
  state_attr_accessor :session_id, :peer_id

  def subscribed
    self.session_id = params[:session_id]
    self.peer_id = params[:peer_id]

    reject unless session_id.present? && peer_id.present?

    # Use signed stream for stateless subscription
    stream_from signed_stream_name("experience_session_#{session_id}")

    # Send current state to the new peer
    transmit({
               api_version: 1,
               type: "state_snapshot",
               state: current_state_hash.to_h,
               timestamp: Time.current.to_i
             })
  end

  def unsubscribed
    # Persist state to DB when a user leaves
    # We parse the experience ID from the session ID (format: exp_{id}_{random})
    return unless session_id.match?(/^exp_\d+_/)

      experience_id = session_id.split("_")[1]
      ExperienceStatePersistJob.perform_later(experience_id, session_id)
  end

  def receive(data)
    case data["type"]
    when "update"
      handle_update(data)
    when "request_state"
      transmit({
                 api_version: 1,
                 type: "state_snapshot",
                 state: current_state_hash.to_h,
                 timestamp: Time.current.to_i
               })
    end
  end

  private

  def current_state_hash
    # Use Kredis to store the state as a hash
    # Key: experience_state:{session_id}
    Kredis.hash("experience_state:#{session_id}")
  end

  def handle_update(data)
    key = data["key"]
    value = data["value"]

    return if key.blank?

    # Update Kredis
    # We store values as JSON strings to handle complex types if needed,
    # but Kredis hash values are strings.
    # If value is an object/array, the client should probably stringify it or we handle it here.
    # For simplicity, let's assume the client sends a value that we can store directly or as JSON.

    # If value is nil, we might want to delete the key
    if value.nil?
      current_state_hash.delete(key)
    else
      current_state_hash[key] = value
    end

    # Broadcast to others using signed stream
    ActionCable.server.broadcast(
      signed_stream_name("experience_session_#{session_id}"), 
      {
        api_version: 1,
        type: "state_update",
        key: key,
        value: value,
        from_peer_id: peer_id,
        timestamp: Time.current.to_i
      }
    )
  end
end
