class CreateUsEsRelations < ActiveRecord::Migration
  def change
    create_table :us_es_relations do |t|
    	t.integer :user_id
    	t.integer :event_id
    	t.timestamps
    end

    add_index :us_es_relations, :user_id
    add_index :us_es_relations, :event_id
    add_index :us_es_relations, [:user_id, :event_id], :unique => true
  end
end
