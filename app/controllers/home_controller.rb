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
      @concierge_service = ab_test("concierge_service2", "true", "false")
      @concierge_service = @concierge_service == "true"

      Analytics.track(
        user_id: distinct_id,
        event: 'View Landing Page',
        properties: {
          'A/B Concierge Service' => @concierge_service,
        }
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

  def concierge
    Analytics.track(
      user_id: distinct_id,
      event: 'View Concierge Service',
    )
  end

  def shiphappens
    throw "This is a test exception, don't worry about it"
  end
end
