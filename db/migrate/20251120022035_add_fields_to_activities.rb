class AddFieldsToActivities < ActiveRecord::Migration[8.0]
  def change
    add_column :activities, :priority, :string
    add_column :activities, :duration, :integer
    add_reference :activities, :user, foreign_key: true
  end
end
