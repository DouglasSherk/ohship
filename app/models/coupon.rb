require 'securerandom'

class Coupon < ActiveRecord::Base
  NO_FEE_SHIPMENT = 0

  belongs_to :shippee, :class_name => 'User'

  before_create :set_defaults

  def set_defaults
    self.coupon_type = NO_FEE_SHIPMENT if self.coupon_type.nil?
    self.expires_at = Date.today.advance(:months => 1) if self.expires_at.nil?
    self.code = SecureRandom.hex if self.code.nil?
  end

  def expired?
    return false if self.expires_at.nil?
    self.expires_at < Date.today
  end

  def used?
    !self.used_at.nil? && !self.shippee.nil?
  end
end
