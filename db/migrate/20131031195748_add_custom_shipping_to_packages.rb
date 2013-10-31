class AddCustomShippingToPackages < ActiveRecord::Migration
  def change
    add_column :packages, :custom_shipping, :boolean, :default => false
  end
end
