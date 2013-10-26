class AddShippingFieldsToPackage < ActiveRecord::Migration
  def change
    add_column :packages, :is_envelope, :integer, :default => 0
    add_column :packages, :shipping_class, :string
    add_column :packages, :shipping_estimate_confirmed, :boolean, :default => false
  end
end
