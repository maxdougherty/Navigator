class CreateSchedules < ActiveRecord::Migration
  def change
    create_table :schedules do |t|
      t.string :title
      t.integer :num_events
      t.boolean :has_events
      t.integer :day
      t.integer :start_time
      t.integer :end_time

      t.timestamps
    end
  end
end
