class Users::RegistrationsController < Devise::RegistrationsController
  def new
    Analytics.track(
      user_id: distinct_id,
      event: 'User Sign Up',
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

    super

    if current_user
      current_user.distinct_id = session[:distinct_id]
      if !current_user.save
        Analytics.track(
          user_id: distinct_id,
          event: 'User Signed Up Failed',
          properties: {
            'Error' => 'Devise signup failed.',
          }
        )
      else
        session.delete(:distinct_id)
        Analytics.track(
          user_id: distinct_id,
          event: 'User Signed Up',
        )
      end
    else
      Analytics.track(
        user_id: distinct_id,
        event: 'User Signed Up Failed',
        properties: {
          'Error' => 'Devise signup failed.',
        }
      )
    end
  end
end
