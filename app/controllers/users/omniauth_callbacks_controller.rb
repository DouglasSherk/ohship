class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def facebook
    # You need to implement the method below in your model (e.g. app/models/user.rb)
    @user = User.find_for_facebook_oauth(request.env["omniauth.auth"], session, current_user, flash[:referrer_id])
    @redirect = flash[:redirect]

    if @user.persisted?
      sign_in_and_redirect @user, :event => :authentication #this will throw if @user is not activated
      set_flash_message(:notice, :success, :kind => "Facebook") if is_navigational_format?
    else
      # The user couldn't be created; this most likely means the email has been used (but not under FB login)
      flash[:error] = "You've registered with that email, but not using Facebook connect. Please login normally with your password."
      redirect_to new_user_session_url
    end
  end
end
