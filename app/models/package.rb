if Rails.env == 'development'
  require_dependency 'usps'
else
  require 'usps'
end

class Package < ActiveRecord::Base
  before_save :order_dimensions

  belongs_to :shippee, :class_name => 'User'
  belongs_to :shipper, :class_name => 'User'
  has_many :photos
  has_one :feedback
  has_one :transaction

  attr_accessor :size_group

  STATE_SUBMITTED = 0        # Submitted, hasn't been matched with a shipper.
  STATE_SHIPPER_MATCHED = 1  # Matched & confirmed by shippee. Shippee sends package & enters tracking
  STATE_SHIPPER_RECEIVED = 2 # Package received by shipper. Shipper updates package details & estimate
  STATE_SHIPPEE_PAID = 3     # Shippee pays fees. Shipper sends package, adds receipt & tracking
  STATE_COMPLETED = 4         # Shippee confirms delivery.

  SHIPPING_CLASSES = {
    'first_class' => 'USPS First Class (up to 11+ days)',
    'priority' => 'USPS Priority (6-10 days)',
    'priority_express' => 'USPS Priority Express (3-5 days)',
  }

  validates :state, :inclusion => { :in => STATE_SUBMITTED..STATE_COMPLETED }
  validates :ship_to_name, :ship_to_address, :ship_to_city, :ship_to_state, :ship_to_country, :ship_to_postal_code,
            :origin_country, :description, presence: true
  validates :ship_to_name, :ship_to_city, :ship_to_state, :ship_to_country, :origin_country,
            length: { in: 1..80 }
  validates :ship_to_address,
            length: { in: 1..255 }
  validates :ship_to_postal_code,
            length: { in: 1..10 }
  validates :shipping_class, :allow_blank => true, :inclusion => { :in => SHIPPING_CLASSES.keys }
  validates :length_in, :width_in, :weight_lb, :value_cents,
            presence: true, numericality: { greater_than: 0 }
  validates :height_in, presence: true, numericality: { greater_than: 0 }, :if => "is_envelope == 0"
  validate :check_shippable, :on => :create

  def sanitize_number(str)
    if str.class == String
      str.delete('$,\'"')
    else
      str
    end
  end

  def value=(val)
    val = sanitize_number(val)
    if val = (Float(val) rescue nil)
      self.value_cents = (val * 100).round
    else
      self.value_cents = nil
    end
  end

  def value
    self.value_cents && self.value_cents / 100.0
  end

  def shipping_estimate=(val)
    val = sanitize_number(val)
    if val = (Float(val) rescue nil)
      self.shipping_estimate_cents = (val * 100).round
    else
      self.shipping_estimate_cents = nil
    end
  end

  def shipping_estimate
    self.shipping_estimate_cents && self.shipping_estimate_cents / 100.0
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

  def cancelable?
    return self.state <= STATE_SHIPPER_MATCHED && self.shippee_tracking.nil?
  end

  def order_dimensions
    self.length_in, self.width_in, self.height_in =
      [self.length_in || 0, self.width_in || 0, self.height_in || 0].sort.reverse
  end

  def check_shippable
    return false if errors.count > 0

    est = USPS.get_shipping_estimate(self)
    if est.empty?
      errors[:package] << 'cannot be shipped - package may be oversized or overweight.'
      return false
    end

    return true
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
        'Shipper received package'
      else
        self.shipping_estimate_confirmed ? 'Payment pending' : 'Package details required'
      end
    when STATE_SHIPPEE_PAID
      if user_type == User::SHIPPEE
        self.shipper_tracking.nil? ? 'Waiting for shipper to send package' : 'Package en route to you'
      else
        self.shipper_tracking.nil? ? 'Payment received' : 'Package en route to user'
      end
    when STATE_COMPLETED
      if user_type == User::SHIPPEE && self.feedback.nil?
        'Leave feedback'
      else
        'Complete'
      end
    else
      'Unknown'
    end
  end
end
