class CreateOpportunities < ActiveRecord::Migration[7.2]
  def change
    create_table :opportunities do |t|
      t.string :opportunity_name
      t.string :account_name
      t.string :type
      t.decimal :amount
      t.string :stage
      t.string :owner
      t.integer :probability
      t.string :contact_name
      t.text :comments
      t.date :closing_date

      t.timestamps
    end
  end
end
