# frozen_string_literal: true
# shareable_constant_value: literal

# Job to generate Federails actors for existing accounts that don't have them yet
class GenerateMissingActorsJob < ApplicationJob
  include SidekiqIteration::Iteration
  queue_as :federation

  def build_enumerator(cursor:)
    # Find accounts that don't have federails actors yet
    Account.left_joins(:federails_actor)
          .where(federails_actors: { id: nil })
          .where(guest: false) # Only non-guest accounts
          .order(:id)
  end

  def each_iteration(account)
    # The Federails::ActorEntity concern should automatically create the actor
    # when we access the federails_actor method, but let's ensure it exists
    if account.federails_actor.nil?
      # Use the new public method to ensure actor creation
      account.ensure_federails_actor!
      Rails.logger.info "Generated federails actor for account #{account.id} (#{account.username})"
    end
  rescue StandardError => e
    Rails.logger.error "Failed to generate federails actor for account #{account.id}: #{e.message}"
  end

  def on_start
    Rails.logger.info "Starting generation of missing federails actors"
  end

  def on_complete
    Rails.logger.info "Completed generation of missing federails actors"
  end
end
