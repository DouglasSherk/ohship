module UserHelper
  def is_shipper?
    current_user.user_type == User::SHIPPER
  end

  def is_shippee?
    current_user.user_type == User::SHIPPEE
  end
end
