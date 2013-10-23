class AddColumnsToPackage < ActiveRecord::Migration
  def change
    add_column :packages, :ship_to_postal_code, :string
    add_column :packages, :special_instructions, :string
  end
end
