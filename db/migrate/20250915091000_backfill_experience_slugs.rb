class BackfillExperienceSlugs < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    say_with_time "Backfilling missing Experience slugs" do
      Experience.reset_column_information
      Experience.find_each do |exp|
        # Skip records that already have a clean, URL-safe slug
        next if exp.slug.present? && exp.slug.match?(/\A[a-z0-9-]+\z/)

        base = exp.send(:normalize_friendly_id, exp.title.to_s)
        base = SecureRandom.hex(6) if base.blank?
        slug = base
        i = 2
        # Ensure uniqueness across the table, excluding the current record (if any)
        while Experience.unscoped.where(slug: slug).where.not(id: exp.id).exists?
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
