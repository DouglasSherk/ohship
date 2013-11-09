class HomeController < ApplicationController
  layout 'application'

  def index
    if current_user
      Analytics.track(
        user_id: current_user.id,
        event: 'View Home Page',
      )
      redirect_to '/packages'
    else
      Analytics.track(
        user_id: User::GUEST_NAME,
        event: 'View Landing Page',
      )
    end
  end

  def details
    Analytics.track(
      user_id: current_user ? current_user.id : User::GUEST_NAME,
      event: 'View How it Works',
    )
  end

  def terms
    Analytics.track(
      user_id: current_user ? current_user.id : User::GUEST_NAME,
      event: 'View Terms of Service',
    )
  end

  def prohibited
    Analytics.track(
      user_id: current_user ? current_user.id : User::GUEST_NAME,
      event: 'View Prohibited Items',
    )
  end
end
