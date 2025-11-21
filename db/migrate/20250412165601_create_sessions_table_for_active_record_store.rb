# frozen_string_literal: true
# shareable_constant_value: literal

class CreateSessionsTableForActiveRecordStore < ActiveRecord::Migration[8.0]
  def change
    # This table is no longer required. Migration left for historical consistency.
    # Intentionally left blank.
  end
end
