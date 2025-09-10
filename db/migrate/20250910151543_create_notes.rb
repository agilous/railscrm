class CreateNotes < ActiveRecord::Migration[7.2]
  def change
    create_table :notes do |t|
      t.text :content
      t.references :notable, polymorphic: true, null: false

      t.timestamps
    end
  end
end
