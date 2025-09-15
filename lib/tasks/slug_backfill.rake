# frozen_string_literal: true

namespace :slugs do
  desc "Backfill slugs for experiences"
  task backfill: :environment do
    puts "Backfilling Experience slugs..."
    Experience.find_each do |exp|
      next if exp.slug.present?

      exp.save!
    end
    puts "Done."
  end
end
