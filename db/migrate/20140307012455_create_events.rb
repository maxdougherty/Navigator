class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.string :title
      t.integer :start_time
      t.integer :end_time

      t.timestamps
    end
  end
end
