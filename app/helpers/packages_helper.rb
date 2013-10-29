module PackagesHelper
  def get_package_tabs
    if is_shippee?
      {'' => 'My Packages', 'complete' => 'Received Packages', 'all' => 'All Packages'}
    else
      {'' => 'My Packages', 'open' => 'Available Packages', 'complete' => 'Completed Packages', 'all' => 'All Packages'}
    end
  end

  def get_package_steps
    if is_shippee?
      ['Find a shipper', 'Send to shipper', 'Pay shipping costs', 'Receive package', 'Leave feedback']
    else
      ['Accept package', 'Receive package', 'Update details', 'Ship package', 'Complete']
    end
  end
end
