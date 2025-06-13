# frozen_string_literal: true

namespace :federation do
  desc "Clean up old federated announcements to prevent database bloat"
  task cleanup_announcements: :environment do
    puts "Cleaning up federated announcements older than 30 days..."

    deleted_count = FederatedAnnouncement.cleanup_old_announcements

    puts "Cleaned up #{deleted_count} old federated announcements"
    puts "Current announcement count: #{FederatedAnnouncement.count}"
  end

  desc "Show federation statistics"
  task stats: :environment do
    puts "=== Federation Statistics ==="
    puts "Local federated experiences: #{Experience.where(federate: true, approved: true).count}"
    puts "Blocked domains: #{BlockedDomain.count}"
    puts "Blocked experiences: #{BlockedExperience.count}"
    puts "Federated announcements: #{FederatedAnnouncement.count}"
    puts "Recent announcements (last 7 days): #{FederatedAnnouncement.where('announced_at > ?', 7.days.ago).count}"

    if BlockedDomain.any?
      puts "\nBlocked domains:"
      BlockedDomain.recent.limit(10).each do |blocked|
        puts "  - #{blocked.domain} (#{blocked.reason || 'No reason given'})"
      end
    end
  end
end
