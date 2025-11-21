# frozen_string_literal: true
# shareable_constant_value: literal

class AddNameToDelayedJobs < ActiveRecord::Migration[8.0]
  def change
    add_column :delayed_jobs, :name, :string
    add_column :delayed_jobs, :cron, :string
    add_column :delayed_jobs, :klass, :string
    add_column :delayed_jobs, :method_name, :string
    add_column :delayed_jobs, :args, :text
  end
end
