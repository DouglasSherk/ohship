class CouponsController < ApplicationController
  before_filter :authenticate_user_with_return!

  def new
    authorize! :create, Coupon

    type = params[:type]

    @coupon = Coupon.new(:type => type)
    if @coupon.save
      redirect_to coupon_path(@coupon.code)
    else
      render 'packages/index', error: 'Could not create coupon.'
    end
  end

  def create
  end

  def show
    @coupon = Coupon.where(:code => params[:id]).first
    if !@coupon.nil? && cannot?(:manage, @coupon)
      if !@coupon.expired? && !@coupon.used?
        @used = true

        current_user.referral_credits = current_user.referral_credits + 1

        @coupon.shippee = current_user
        @coupon.used_at = Date.today
        if !current_user.save || !@coupon.save
          @error = true
        end
      end
    end
  end
end
