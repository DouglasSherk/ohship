class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  layout 'content'

  before_action :configure_devise_permitted_parameters, if: :devise_controller?
  before_action :maybe_identify_user

  def self.identify_user(user, _session)
    _session[:identified] = true
    Analytics.identify(
      user_id: user.id,
      traits: {
        # Built-in traits.
        name: user.name,
        email: user.email,
        created: user.created_at,

        # Custom traits.
        'User Type' => user.user_type,
        'Referral Credits' => user.referral_credits,
        'Provider' => user.provider,
      },
    )
  end

  Warden::Manager.after_authentication do |user, auth, opts|
    identify_user(user, auth.env['rack.session'])
  end

  def maybe_identify_user
    self.class.identify_user(current_user, session) if current_user && !session[:identified]
  end

  def after_inactive_sign_up_path_for(resource)
    new_package_path(:signup => true)
  end

  def after_sign_up_path_for(resource)
    new_package_path(:signup => true)
  end

  def after_sign_in_path_for(resource)
    return @redirect if !@redirect.blank?

    # XXX: Neither of |after_sign_up_path_for| or |after_inactive_sign_up_for|
    # seem to get called, so use this workaround instead. The user is marked
    # as new in the user model.
    if current_user && current_user.is_new
      current_user.is_new = false
      return new_package_path(:signup => true)
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
