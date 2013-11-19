class HomeController < ApplicationController
  def index
    if current_user
      Analytics.track(
        user_id: distinct_id,
        event: 'View Home Page',
      )
      return redirect_to '/packages'
    else
      @concierge_service = ab_test("concierge_service2", "true", "false") == "true"
      @get_started_button = ab_test("get_started_button", "red", "green")

      Analytics.track(
        user_id: distinct_id,
        event: 'View Landing Page',
        properties: {
          'A/B Concierge Service' => @concierge_service,
          'A/B Get Started Button' => @get_started_button,
        }
      )
    end

    render :layout => 'application'
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

  def refer
    Analytics.track(
      user_id: distinct_id,
      event: 'View Refer a Friend',
    )
  end

  def shiphappens
    throw "This is a test exception, don't worry about it"
  end
end
