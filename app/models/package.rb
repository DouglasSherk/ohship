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

  # Fields:
  #   # State of shippee - shipper flow
  #   t.integer :state, :default => 0

  #   # Package description
  #   t.float :length_cm
  #   t.float :width_cm
  #   t.float :height_cm
  #   t.float :weight_kg
  #   t.integer :value_cents
  #   t.string :description

  #   # Address to ship to
  #   t.string :ship_to_name
  #   t.string :ship_to_address
  #   t.string :ship_to_city
  #   t.string :ship_to_country

  #   # Payment from shippee
  #   t.references :transaction

  #   # Tracking numbers (and carriers)
  #   t.string :shippee_tracking
  #   t.string :shippee_tracking_carrier
  #   t.string :shipper_tracking
  #   t.string :shipper_tracking_carrier

  def value=(val)
    p val
    self.value_cents = (val.to_i * 100).round
  end

  def value
    self.value_cents && self.value_cents / 100.0
  end

  def state_to_s
    case self.state
    when STATE_SUBMITTED
      'Waiting for match with shipper'
    when STATE_SHIPPER_MATCH
      'Matched with shipper'
    when STATE_SHIPPEE_SENT
      'In transit to shipper'
    when STATE_SHIPPER_RECEIVED
      'Shipper received'
    when STATE_SHIPPEE_PAID
      'Waiting for shipper to send'
    when STATE_SHIPPER_SENT
      'In transit to you'
    when STATE_RECEIVED
      'Complete'
    else
      'Unknown'
    end
  end
end
