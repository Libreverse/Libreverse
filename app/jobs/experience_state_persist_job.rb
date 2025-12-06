class ExperienceStatePersistJob < ApplicationJob
  queue_as :default

  def perform(experience_id, session_id)
    experience = Experience.find_by(id: experience_id)
    return unless experience

    # Fetch state from Kredis
    kredis_hash = Kredis.hash("experience_state:#{session_id}")
    current_state = kredis_hash.to_h

    # Save to DB
    experience.update(current_state: current_state)
  end
end
