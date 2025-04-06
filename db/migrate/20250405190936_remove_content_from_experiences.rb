class RemoveContentFromExperiences < ActiveRecord::Migration[8.0]
  def change
    remove_column :experiences, :content, :text
    remove_column :experiences, :AddHtmlAttachmentToExperiences, :string
  end
end
