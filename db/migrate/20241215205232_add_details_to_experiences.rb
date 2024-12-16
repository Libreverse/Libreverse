class AddDetailsToExperiences < ActiveRecord::Migration[8.0]
  def change
    add_column :experiences, :title, :string
    add_column :experiences, :description, :text
    add_column :experiences, :author, :string
  end
end
