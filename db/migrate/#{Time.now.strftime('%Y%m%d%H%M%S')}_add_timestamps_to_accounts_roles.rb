class AddTimestampsToAccountsRoles < ActiveRecord::Migration[7.0]
  def change
    add_column :accounts_roles, :created_at, :datetime, null: false, default: -> { 'CURRENT_TIMESTAMP' }
    add_column :accounts_roles, :updated_at, :datetime, null: false, default: -> { 'CURRENT_TIMESTAMP' }
  end
end
