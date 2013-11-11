class CouponsController < ApplicationController
  before_filter :authenticate_user_with_return!

  def new
    authorize! :create, Coupon

    coupon_type = params[:coupon_type]

    @coupon = Coupon.new(:coupon_type => coupon_type)
    if @coupon.save
      Analytics.track(
        user_id: distinct_id,
        event: 'Admin Coupon Create',
        properties: serialize_resource,
      )

      if coupon_type == Coupon::NO_FEE_SHIPMENT
        Analytics.track(
          user_id: distinct_id,
          event: 'User Referral Credit Create',
          properties: serialize_resource,
        )
      end

      redirect_to coupon_path(@coupon.code)
    else
      flash[:error] = 'Could not create coupon.'

      Analytics.track(
        user_id: distinct_id,
        event: 'Admin Coupon Create Failed',
        properties: serialize_resource.merge({
          'Error' => flash[:error],
        }),
      )

      render 'packages/index', error: flash[:error]
    end
  end

  def create
  end

  def show
    @coupon = Coupon.where(:code => params[:id]).first
    if !@coupon.nil? && cannot?(:manage, @coupon) && current_user.user_type == User::SHIPPEE
      if !@coupon.expired? && !@coupon.used?
        @used = true

        if @coupon.coupon_type == Coupon::NO_FEE_SHIPMENT
          current_user.referral_credits = current_user.referral_credits + 1
        end

        @coupon.shippee = current_user
        @coupon.used_at = Date.today
        if !current_user.save || !@coupon.save
          flash[:error] = 'Error redeeming coupon.'
          @error = true

          Analytics.track(
            user_id: distinct_id,
            event: 'User Coupon Redeem Failed',
            properties: serialize_resource.merge({
              'Error' => flash[:error],
            }),
          )
        else
          if @coupon.coupon_type == Coupon::NO_FEE_SHIPMENT
            Analytics.track(
              user_id: distinct_id,
              event: 'User Referral Credit Redeem',
              properties: serialize_resource,
            )
          end

          Analytics.track(
            user_id: distinct_id,
            event: 'User Coupon Redeem',
            properties: serialize_resource,
          )
        end
      end
    end
  end
end
