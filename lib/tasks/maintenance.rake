# frozen_string_literal: true

namespace :maintenance do
  desc "Purge expired Rodauth tokens & stale sessions"
  task retention: :environment do
    # Enqueue the Solid Queue job so it can run async or inline depending on env
    PurgeRodauthTokensJob.perform_now

    # Remove sessions older than 14 days (only relevant if AR session store ever enabled)
    if defined?(ActiveRecord::SessionStore::Session)
      cutoff = 14.days.ago
      ActiveRecord::SessionStore::Session.where("updated_at < ?", cutoff).delete_all
    end
  end
end
