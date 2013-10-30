class UsersController < ApplicationController
  before_filter :authenticate_user!

  def profile
    @user = current_user
    @signup = params[:signup]
    @country = @user.country || User.guess_user_country(request.remote_ip)
    @referral_count = @user.referrals.length
    @referral_success = @user.referrals.select { |ref|
      Package.where(:shippee => ref, :state => Package::STATE_COMPLETED).first
    }.count
  end

  def update
    @user = current_user
    if !params[:user][:password].blank?
      if @user.update_with_password(user_params)
        flash[:change_notice] = 'Successfully changed password.'
        # Usually changing password requires a re-log. Bypass that
        sign_in @user, :bypass => true
      end
    elsif @user.update_attributes(user_params.except :current_password, :password, :password_confirmation)
      flash[:change_notice] = 'Successfully changed profile.'
    end

    profile
    render action: 'profile'
  end

  private
    def user_params
      params.require(:user).permit(
        :name,
        :email,
        :address,
        :city,
        :state,
        :country,
        :postal_code,
        :current_password,
        :password,
        :password_confirmation
      )
    end
end
