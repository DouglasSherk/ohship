class Users::SessionsController < Devise::SessionsController
  def new
    @redirect = flash[:redirect] = params[:redirect]

    Analytics.track(
      user_id: distinct_id,
      event: 'User Login Begin',
    )

    super
  end

  def destroy
    Analytics.track(
      user_id: distinct_id,
      event: 'User Logout',
    )

    super
  end

  def create
    @redirect = params[:redirect]

    Analytics.track(
      user_id: distinct_id,
      event: 'User Login',
    )

    super
  end
end
