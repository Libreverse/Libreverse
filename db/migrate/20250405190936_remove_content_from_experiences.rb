# typed: true
# frozen_string_literal: true
# shareable_constant_value: literal

class RemoveContentFromExperiences < ActiveRecord::Migration[8.0]
  def change
    remove_column :experiences, :content, :text
    # The AddHtmlAttachmentToExperiences column doesn't exist, so we'll skip it
  end
end
