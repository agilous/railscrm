class CreatePipedriveMappings < ActiveRecord::Migration[8.0]
  def change
    create_table :pipedrive_mappings do |t|
      t.string :pipedrive_type, null: false
      t.integer :pipedrive_id, null: false
      t.integer :rails_id, null: false

      t.timestamps
    end

    add_index :pipedrive_mappings, [ :pipedrive_type, :pipedrive_id ], unique: true
    add_index :pipedrive_mappings, :rails_id
  end
end
