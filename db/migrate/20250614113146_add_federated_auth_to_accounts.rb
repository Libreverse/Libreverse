class AddFederatedAuthToAccounts < ActiveRecord::Migration[8.0]
  def change
    add_column :accounts, :federated_id, :string
    add_column :accounts, :provider, :string
    add_column :accounts, :provider_uid, :string

    # Add indexes for efficient lookups
    add_index :accounts, :federated_id
    add_index :accounts, %i[provider provider_uid], unique: true
  end
end
