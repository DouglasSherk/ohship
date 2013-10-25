class AddEstimateToPackage < ActiveRecord::Migration
  def change
    add_column :packages, :shipping_estimate_cents, :integer
  end
end
