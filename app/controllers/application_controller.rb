class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  layout 'content'

  # XXX: If we ever make users confirmable, we must update
  # this to |after_inactive_sign_up_path_for|.
  def after_sign_up_path_for(resource)
    users_profile_path(:signup => true)
  end

  def after_sign_in_path_for(resource)
    #users_profile_path(:signup => true)
    '/packages'
  end
end
