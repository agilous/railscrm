class CreateLeads < ActiveRecord::Migration[7.2]
  def change
    create_table :leads do |t|
      t.string :first_name
      t.string :last_name
      t.string :company
      t.string :email
      t.string :phone
      t.string :address
      t.string :city
      t.string :state
      t.string :zip
      t.string :interested_in
      t.text :comments
      t.string :lead_status
      t.string :lead_source
      t.string :lead_owner
      t.string :account_name
      t.string :opportunity_name
      t.string :opportunity_owner
      t.references :assigned_to, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
