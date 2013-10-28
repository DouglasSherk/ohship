class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  layout 'content'

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
end
