class CreateTasks < ActiveRecord::Migration[7.2]
  def change
    create_table :tasks do |t|
      t.string :title
      t.text :description
      t.datetime :due_date
      t.boolean :completed
      t.string :priority
      t.references :assignee, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
