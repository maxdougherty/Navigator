class CreateUsSsRelations < ActiveRecord::Migration
  def change
    create_table :us_ss_relations do |t|
    	t.integer :user_id
    	t.integer :schedule_id
    	t.timestamps
    end

    add_index :us_ss_relations, :user_id
    add_index :us_ss_relations, :schedule_id
    add_index :us_ss_relations, [:user_id, :schedule_id], :unique => true
  end
end
