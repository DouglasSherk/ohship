class HomeController < ApplicationController
  layout 'application'

  def index
    if current_user
      Analytics.track(
        user_id: distinct_id,
        event: 'View Home Page',
      )
      redirect_to '/packages'
    else
      Analytics.track(
        user_id: distinct_id,
        event: 'View Landing Page',
      )
    end
  end

  def details
    Analytics.track(
      user_id: distinct_id,
      event: 'View How it Works',
    )
  end

  def terms
    Analytics.track(
      user_id: distinct_id,
      event: 'View Terms of Service',
    )
  end

  def prohibited
    Analytics.track(
      user_id: distinct_id,
      event: 'View Prohibited Items',
    )
  end

  def shiphappens
    throw "This is a test exception, don't worry about it"
  end
end
