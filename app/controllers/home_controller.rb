class HomeController < ApplicationController
  layout 'application'

  def index
    if current_user
      redirect_to '/packages'
    else
      Analytics.track(
        user_id: User::GUEST_NAME,
        event: 'Landing Page',
      )
    end
  end

  def details
  end

  def terms
  end

  def prohibited
  end
end
