class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  layout 'content'

  before_action :configure_devise_permitted_parameters, if: :devise_controller?
  after_action :analytics_track

  Warden::Manager.after_authentication do |user, auth, opts|
    Analytics.identify(
      user_id: user.id,
      traits: {
        name: user.name,
        email: user.email,
        user_type: user.user_type,
        referral_credits: user.referral_credits,
        country: user.country,
        provider: user.provider,
      }
    )
  end

  def analytics_track
    Analytics.track(
      user_id: current_user ? current_user.id : User::GUEST_NAME,
      event: 'View ' + params[:controller].capitalize + ' ' + params[:action].capitalize,
      properties: params.select{ |k, v| !['controller', 'action'].include?(k) },
    )
  end

  def after_inactive_sign_up_path_for(resource)
    packages_path(:signup => true)
  end

  def after_sign_up_path_for(resource)
    packages_path(:signup => true)
  end

  def after_sign_in_path_for(resource)
    return @redirect if !@redirect.blank?

    # XXX: Neither of |after_sign_up_path_for| or |after_inactive_sign_up_for|
    # seem to get called, so use this workaround instead. The user is marked
    # as new in the user model.
    if current_user && current_user.is_new
      current_user.is_new = false
      return packages_path(:signup => true)
    end

    packages_path
  end

  protected

  def configure_devise_permitted_parameters
    registration_params = [:name, :email, :password, :password_confirmation]

    if params[:action] == 'update'
      devise_parameter_sanitizer.for(:account_update) {
        |u| u.permit(registration_params << :current_password)
      }
    elsif params[:action] == 'create'
      devise_parameter_sanitizer.for(:sign_up) {
        |u| u.permit(registration_params << :referrer_id)
      }
    end
  end

  # If authentication fails, redirect to sign-in with a return URL upon successful signin.
  def authenticate_user_with_return!
    if !current_user
      redirect_to new_user_session_url(:redirect => request.path)
    end
  end
end
