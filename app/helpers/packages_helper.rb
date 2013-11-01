module PackagesHelper
  def package_status(package)
    user_type = current_user.user_type

    case package.state
    when Package::STATE_SUBMITTED
      if is_shippee?
        package.shipper.nil? ? 'Finding OhShip location' : 'Matched with OhShip location'
      else
        package.shipper.nil? ? 'Shipper required' : 'Pending user confirmation'
      end
    when Package::STATE_SHIPPER_MATCHED
      if is_shippee?
        package.shippee_tracking.nil? ? 'OhShip location found' : 'En route to OhShip location'
      else
        package.shippee_tracking.nil? ? 'Waiting for user to ship package' : 'Package en route to you'
      end
    when Package::STATE_SHIPPER_RECEIVED
      if is_shippee?
        package.shipping_estimate_confirmed ? 'Payment pre-authorization' : 'OhShip received package'
      else
        package.shipping_estimate_confirmed ? 'Waiting for user payment' : 'Package details required'
      end
    when Package::STATE_SHIPPEE_PAID
      if is_shippee?
        package.shipper_tracking.nil? ? 'Waiting for OhShip to send' : 'Package en route to you'
      else
        package.shipper_tracking.nil? ? 'Ready to send' : 'Package en route to user'
      end
    when Package::STATE_COMPLETED
      if is_shippee? && package.feedback.nil?
        'Leave feedback'
      else
        'Complete'
      end
    else
      'Unknown'
    end
  end

  def package_action_required?(package)
    user_type = current_user.user_type

    case package.state
    when Package::STATE_SUBMITTED
      false
    when Package::STATE_SHIPPER_MATCHED
      is_shipper? ^ package.shippee_tracking.nil?
    when Package::STATE_SHIPPER_RECEIVED
      is_shipper? ^ package.shipping_estimate_confirmed
    when Package::STATE_SHIPPEE_PAID
      is_shippee? ^ package.shipper_tracking.nil?
    when Package::STATE_COMPLETED
      is_shippee? && package.feedback.nil?
    else
      false
    end
  end

  def no_more_actions?(package)
    package.state == Package::STATE_COMPLETED && !package_action_required?(package)
  end

  def get_shipping_companies
    ['USPS', 'UPS', 'FedEx', 'DHL', 'Other']
  end

  def get_package_tabs
    if is_shippee?
      {'' => 'My Packages', 'complete' => 'Received Packages', 'all' => 'All Packages'}
    else
      {'' => 'My Packages', 'open' => 'Available Packages', 'complete' => 'Completed Packages', 'all' => 'All Packages'}
    end
  end

  def get_package_steps
    if is_shippee?
      ['Find an OhShip location', 'Send to OhShip location', 'Pre-authorize payment', 'Receive package', 'Leave feedback']
    else
      ['Accept package', 'Receive package', 'Update details', 'Ship package', 'Complete']
    end
  end

  def number_to_local_currency(amount, country)
    require 'currencies/exchange_bank'
    currency = Package::COUNTRY_DATA[country][:currency]
    amount = ISO4217::Currency::ExchangeBank.instance.exchange((amount*100).round, 'USD', currency)/100.0
    number_to_currency(amount) + " " + currency
  end
end
