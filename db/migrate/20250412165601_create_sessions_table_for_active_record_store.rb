class CreateSessionsTableForActiveRecordStore < ActiveRecord::Migration[8.0]
  def change
    create_table :sessions_table_for_active_record_stores, &:timestamps
  end
end
