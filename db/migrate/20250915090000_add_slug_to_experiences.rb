# frozen_string_literal: true

class AddSlugToExperiences < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    add_column :experiences, :slug, :string
    add_index :experiences, :slug, unique: true

    # Backfill slugs for existing records
    say_with_time "Backfilling Experience slugs" do
      # Load the bare model to avoid callbacks that might depend on app code changes
      Experience.reset_column_information
      Experience.find_each do |exp|
        next if exp.slug.present?

        # Using FriendlyId generation via to_param path
        generated = exp.send(:normalize_friendly_id, exp.send(:slug_candidates).first)
        exp.update_column(:slug, generated.presence || SecureRandom.hex(4)) # rubocop:disable Rails/SkipsModelValidations
      end
    end
  end

  def down
    remove_index :experiences, :slug if index_exists?(:experiences, :slug)
    remove_column :experiences, :slug if column_exists?(:experiences, :slug)
  end
end
