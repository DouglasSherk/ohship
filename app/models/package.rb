class Package < ActiveRecord::Base
  belongs_to :shippee, :class_name => 'User'
  belongs_to :shipper, :class_name => 'User'
  has_many :photos

  validates :state, :inclusion => { :in => 0..6 }

  STATE_SUBMITTED = 0
  STATE_SHIPPER_MATCH = 1
  STATE_SHIPPEE_SENT = 2
  STATE_SHIPPER_RECEIVED = 3
  STATE_SHIPPEE_PAID = 4
  STATE_SHIPPER_SENT = 5
  STATE_RECEIVED = 6
end
