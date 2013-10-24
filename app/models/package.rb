class Package < ActiveRecord::Base
  belongs_to :shippee, :class_name => 'User'
  belongs_to :shipper, :class_name => 'User'
  has_many :photos

  STATE_SUBMITTED = 0        # Submitted, hasn't been matched with a shipper.
  STATE_SHIPPER_MATCHED = 1  # Matched & confirmed by shippee. Shippee sends package & enters tracking
  STATE_SHIPPER_RECEIVED = 2 # Package received by shipper. Shipper updates package details & estimate
  STATE_SHIPPEE_PAID = 3     # Shippee pays fees. Shipper sends package, adds receipt & tracking
  STATE_COMPLETED = 4         # Shippee confirms delivery.

  validates :state, :inclusion => { :in => STATE_SUBMITTED..STATE_COMPLETED }

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
    return {
      STATE_SUBMITTED => 'submitted',
      STATE_SHIPPER_MATCHED => 'matched',
      STATE_SHIPPER_RECEIVED => 'received',
      STATE_SHIPPEE_PAID => 'paid',
      STATE_COMPLETED => 'completed'
    }[self.state]
  end

  def status(user_type)
    case self.state
    when STATE_SUBMITTED
      if user_type == User::SHIPPEE
        self.shipper.nil? ? 'Waiting for match with shipper' : 'Matched with shipper'
      else
        self.shipper.nil? ? 'Shipper required' : 'Pending user confirmation'
      end
    when STATE_SHIPPER_MATCHED
      if user_type == User::SHIPPEE
        self.shippee_tracking.nil? ? 'Send package to shipper' : 'En route to shipper'
      else
        self.shippee_tracking.nil? ? 'Waiting for user to send package' : 'Package en route to you'
      end
    when STATE_SHIPPER_RECEIVED
      if user_type == User::SHIPPEE
        'Shipper received package, payment pending'
      else
        'Payment pending'
      end
    when STATE_SHIPPEE_PAID
      if user_type == User::SHIPPEE
        self.shipper_tracking.nil? ? 'Waiting for shipper to send package' : 'Package en route to you'
      else
        self.shipper_tracking.nil? ? 'Payment received' : 'Package en route to user'
      end
    when STATE_COMPLETED
      'Complete'
    else
      'Unknown'
    end
  end
end
