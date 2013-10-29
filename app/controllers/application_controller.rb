class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  layout 'content'

  before_action :configure_devise_permitted_parameters, if: :devise_controller?

  def after_inactive_sign_up_path_for(resource)
    packages_path(:signup => true)
  end

  def after_sign_up_path_for(resource)
    packages_path(:signup => true)
  end

  def after_sign_in_path_for(resource)
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
end
