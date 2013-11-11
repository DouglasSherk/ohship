class FixCouponType < ActiveRecord::Migration
  def change
    rename_column :coupons, :type, :coupon_type
  end
end
