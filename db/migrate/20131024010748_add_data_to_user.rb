class AddDataToUser < ActiveRecord::Migration
  def change
    add_column :users, :name, :string
    add_column :users, :address, :string
    add_column :users, :city, :string
    add_column :users, :state, :string
    add_column :users, :country, :string
    add_column :users, :postal_code, :string

    add_column :packages, :origin_country, :string
    add_column :packages, :ship_to_state, :string
  end
end
