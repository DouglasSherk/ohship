class AddReferralFieldsToUser < ActiveRecord::Migration
  def change
    add_column :users, :referrer_id, :integer
    add_column :users, :referral_credits, :integer, :default => 0
  end
end
