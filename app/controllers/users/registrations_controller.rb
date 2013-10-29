class Users::RegistrationsController < Devise::RegistrationsController
  def create
    if params[:email_only]
      @email_only = true
      build_resource sign_up_params
      return render action: 'new'
    end

    super
  end
end
