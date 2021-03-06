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
  STATE_COMPLETED = 4        # Shippee confirms delivery.

  COUNTRY_DATA = {
    'United States' => {:carrier => 'USPS', :url => 'http://postcalc.usps.com/', :currency => 'USD'},
    'United Kingdom' => {:carrier => 'Royal Mail', :url => 'http://www.royalmail.com/price-finder', :currency => 'GBP'},
    'France' => {:carrier => 'FedEx France', :url => 'https://www.fedex.com/ratefinder/home?cc=fr', :currency => 'EUR'},
    'Hong Kong' => {:carrier => 'Hongkong Post', :url => 'http://app1.hongkongpost.hk/calc/eng/index.php', :currency => 'HKD'},
    'Canada' => {:carrier => 'Canada Post', :url => 'http://www.canadapost.ca/cpotools/apps/far/business/findARate?execution=e2s2', :currency => 'CAD'},
    'Australia' => {:carrier => 'Australia Post', :url => 'http://auspost.com.au/apps/postage-calculator.html', :currency => 'AUD'},
  }

  SHIPPING_SIZES = {
    'envelope' => { :length_in => 12, :width_in => 12, :height_in => 0.75 },
    'small' => { :length_in => 12, :width_in => 12, :height_in => 3 },
    'medium' => { :length_in => 12, :width_in => 12, :height_in => 5 },
    'large' => { :length_in => 15, :width_in => 15, :height_in => 10 },
  }

  validates :state, :inclusion => { :in => STATE_SUBMITTED..STATE_COMPLETED }

  # Shipping details
  validates :ship_to_name, :ship_to_address, :ship_to_city, :ship_to_state, :ship_to_postal_code, :ship_to_country,
            :origin_country, :description, presence: true
  validates :ship_to_name, :ship_to_city, :ship_to_state, :ship_to_country, :origin_country,
            length: { in: 1..80 }
  validates :ship_to_address, length: { in: 1..255 }
  validates :ship_to_address2, length: { maximum: 255 }
  validates :ship_to_postal_code,
            length: { in: 1..10 }
  validates :origin_country, :inclusion => { :in => COUNTRY_DATA.keys }

  # Dimensions
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

    # Can't auto-validate these yet.
    return true if self.origin_country != 'United States'

    est = USPS.get_shipping_estimate(self)
    if est.empty?
      errors[:package] << 'cannot be shipped - package may be oversized or overweight.'
      return false
    end

    return true
  end
end
