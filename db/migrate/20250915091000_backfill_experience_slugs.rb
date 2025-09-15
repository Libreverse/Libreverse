# frozen_string_literal: true

class BackfillExperienceSlugs < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    say_with_time "Backfilling missing Experience slugs" do
      Experience.reset_column_information
      Experience.find_each do |exp|
        next if exp.slug.present?

        base = exp.send(:normalize_friendly_id, exp.title.to_s)
        base = SecureRandom.hex(6) if base.blank?
        slug = base
        i = 2
        while Experience.unscoped.where(slug: slug).exists?
          slug = "#{base}-#{i}"
          i += 1
        end

        exp.update_column(:slug, slug) # rubocop:disable Rails/SkipsModelValidations
      end
    end
  end

  def down
    # no-op: do not remove slugs in down migration
  end
end
