class CreateAccountRoles < ActiveRecord::Migration[8.0]
  def change
    create_table :account_roles do |t|
      t.references :account, null: false, foreign_key: true
      t.references :role, null: false, foreign_key: true
      t.timestamps
    end
    add_index :account_roles, %i[account_id role_id], unique: true
  end
end
