# frozen_string_literal: true

# Job to generate Federails actors for existing accounts that don't have them yet
class GenerateMissingActorsJob < ApplicationJob
  queue_as :federation

  def perform
    # Find accounts that don't have federails actors yet
    accounts_without_actors = Account.left_joins(:federails_actor)
                                     .where(federails_actors: { id: nil })
                                     .where(guest: false) # Only non-guest accounts

    generated_count = 0

    accounts_without_actors.find_each do |account|
        # The Federails::ActorEntity concern should automatically create the actor
        # when we access the federails_actor method, but let's ensure it exists
        if account.federails_actor.nil?
          # Use the new public method to ensure actor creation
          account.ensure_federails_actor!
          generated_count += 1
          Rails.logger.info "Generated federails actor for account #{account.id} (#{account.username})"
        end
    rescue StandardError => e
        Rails.logger.error "Failed to generate federails actor for account #{account.id}: #{e.message}"
    end

    Rails.logger.info "Generated #{generated_count} federails actors"
    generated_count
  end
end
