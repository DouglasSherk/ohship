class AddAddressLine2 < ActiveRecord::Migration
  def change
    add_column :users, :address2, :string
    add_column :packages, :ship_to_address2, :string
  end
end
