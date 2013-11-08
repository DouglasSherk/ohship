class CreateCoupons < ActiveRecord::Migration
  def change
    create_table :coupons do |t|
      t.references :shippee

      t.string :code
      t.integer :type
      t.datetime :used_at
      t.datetime :expires_at

      t.timestamps
    end
  end
end
