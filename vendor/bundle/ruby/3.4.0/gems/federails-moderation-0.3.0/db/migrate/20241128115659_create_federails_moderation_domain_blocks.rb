class CreateFederailsModerationDomainBlocks < ActiveRecord::Migration[7.0]
  def change
    create_table :federails_moderation_domain_blocks do |t|
      t.string "domain", null: false, index: { unique: true }
      t.timestamps
    end
  end
end
