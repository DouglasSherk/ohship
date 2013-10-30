class Users::SessionsController < Devise::SessionsController
  def new
    @redirect = flash[:redirect] = params[:redirect]
    super
  end

  def create
    @redirect = params[:redirect]
    super
  end
end
