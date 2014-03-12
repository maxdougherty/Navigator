class CreateSsEsRelations < ActiveRecord::Migration
  def change
    create_table :ss_es_relations do |t|
    	t.integer :schedule_id
    	t.integer :event_id
    	t.timestamps
    end

    add_index :ss_es_relations, :schedule_id
    add_index :ss_es_relations, :event_id
    add_index :ss_es_relations, [:schedule_id, :event_id], :unique => true
  end
end
