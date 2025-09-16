# frozen_string_literal: true

class AddSlugToExperiences < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    # Add column if it doesn't already exist
    add_column :experiences, :slug, :string unless column_exists?(:experiences, :slug)

    # Ensure we have a unique index on slug. If a non-unique index exists, replace it.
    unless index_exists?(:experiences, :slug, unique: true)
      remove_index :experiences, :slug if index_exists?(:experiences, :slug)
      add_index :experiences, :slug, unique: true
    end

    # Backfill slugs for existing records
    return unless column_exists?(:experiences, :slug)

      say_with_time "Backfilling Experience slugs" do
        # Load the bare model to avoid callbacks that might depend on app code changes
        Experience.reset_column_information
        Experience.where(slug: [ nil, '' ]).find_each do |exp|
          # Prefer FriendlyId generation when available; fall back to parameterized title
          generated = begin
            if exp.respond_to?(:normalize_friendly_id) && exp.respond_to?(:slug_candidates)
              exp.send(:normalize_friendly_id, exp.send(:slug_candidates).first)
            else
              exp.title.to_s.parameterize
            end
          rescue StandardError
            exp.title.to_s.parameterize
          end

          exp.update_column(:slug, generated.presence || SecureRandom.hex(4)) # rubocop:disable Rails/SkipsModelValidations
        end
      end
  end

  def down
    remove_index :experiences, :slug if index_exists?(:experiences, :slug)
    remove_column :experiences, :slug if column_exists?(:experiences, :slug)
  end
end
