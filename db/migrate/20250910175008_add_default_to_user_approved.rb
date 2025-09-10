class AddDefaultToUserApproved < ActiveRecord::Migration[7.2]
  def change
    change_column_default :users, :approved, from: nil, to: true
    change_column_default :users, :admin, from: nil, to: false
  end
end
