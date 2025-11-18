class CreateActivities < ActiveRecord::Migration[8.0]
  def change
    create_table :activities do |t|
      t.references :contact, null: false, foreign_key: true
      t.string :activity_type, null: false
      t.string :title, null: false
      t.text :description
      t.datetime :due_date
      t.datetime :completed_at

      t.timestamps
    end
  end
end
