class Users::RegistrationsController < Devise::RegistrationsController
  def new
    Analytics.track(
      user_id: User::GUEST_NAME,
      event: 'Sign Up',
    )

    # Persist this in the session for the next request
    @referrer_id = flash[:referrer_id] = flash[:referrer_id] || params[:referrer_id]
    super
  end

  def create
    @referrer_id = params[:user][:referrer_id]

    if params[:email_only]
      @email_only = true
      build_resource sign_up_params
      return render action: 'new'
    end

    Analytics.track(
      user_id: User::GUEST_NAME,
      event: 'Signed Up',
    )

    super
  end
end
