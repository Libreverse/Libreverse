# typed: true
# frozen_string_literal: true
# shareable_constant_value: literal

class AddMarkdownToSnippets < ActiveRecord::Migration[7.1]
  def change
    add_column :comfy_cms_snippets, :markdown, :boolean, default: false
  end
end
