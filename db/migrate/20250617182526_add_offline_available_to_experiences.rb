class AddOfflineAvailableToExperiences < ActiveRecord::Migration[8.0]
  def change
    add_column :experiences, :offline_available, :boolean, default: false, null: false
  end
end
