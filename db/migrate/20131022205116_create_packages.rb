class CreatePackages < ActiveRecord::Migration
  def change
    create_table :packages do |t|
      t.references :shippee
      t.references :shipper

      # State of shippee - shipper flow
      t.integer :state, :default => 0

      # Package description
      t.float :length_cm
      t.float :width_cm
      t.float :height_cm
      t.float :weight_kg
      t.integer :value_cents
      t.string :description

      # Address to ship to
      t.string :ship_to_name
      t.string :ship_to_address
      t.string :ship_to_city
      t.string :ship_to_country

      # Payment from shippee
      t.references :transaction

      # Tracking numbers (and carriers)
      t.string :shippee_tracking
      t.string :shippee_tracking_carrier
      t.string :shipper_tracking
      t.string :shipper_tracking_carrier

      t.timestamps
    end
  end
end
