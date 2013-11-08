if Rails.env == 'development'
  require_dependency 'usps'
else
  require 'usps'
end

require 'stripe'
require 'currencies/exchange_bank'

class PackagesController < ApplicationController
  before_filter :authenticate_user_with_return!
  load_and_authorize_resource :except => [:index, :new, :create]
  skip_authorize_resource :only => [:cancel, :shippee_action, :shipper_action, :admin_action]

  # GET /packages
  # GET /packages.json
  def index
    @signup = params[:signup]
    @packages = Package.all.select { |package| can? :read, package }

    @show = params[:show] || ''
    if current_user.user_type == User::SHIPPER
      if @show.blank? # default: my packages
        @packages = @packages.select { |package| package.shipper == current_user }
      elsif @show == 'open'
        @packages = @packages.select { |package| package.shipper.nil? }
      end
    end

    if @show == 'complete'
      @packages = @packages.select do |package|
       package.state == Package::STATE_COMPLETED &&
         (current_user.user_type == User::SHIPPER || package.feedback)
      end
    elsif @show != 'all'
      @packages = @packages.select do |package|
       package.state != Package::STATE_COMPLETED ||
         (current_user.user_type == User::SHIPPEE && package.feedback.nil?)
      end
    end

    if current_user.user_type == User::SHIPPER
      #@packages = @packages.select { |package| package.origin_country == current_user.country }
    end
  end

  # GET /packages/1
  # GET /packages/1.json
  def show
    @shippers = User.where(:user_type => User::SHIPPER, :country => @package.origin_country) if can? :admin, @package

    # Load shipping estimates from USPS
    if current_user.user_type == User::SHIPPEE &&
       @package.state == Package::STATE_SHIPPER_RECEIVED &&
       @package.shipping_estimate_confirmed &&
       @package.shipping_estimate.nil?
      # Can't use ||= here; we need to set it to something no matter what to refresh it.
      flash[:estimates] = flash[:estimates] || USPS.get_shipping_estimate(@package)
    end

    @photos = @package.photos.where(:photo_type => 'photo')
    @receipt = @package.photos.where(:photo_type => 'receipt').first
  end

  # GET /packages/new
  def new
    authorize! :create, Package
    @package = Package.new

    # Load user's address as the default
    @package.ship_to_name = current_user.name
    @package.ship_to_address = current_user.address
    @package.ship_to_city = current_user.city
    @package.ship_to_state = current_user.state
    @package.ship_to_country = current_user.country
    @package.ship_to_postal_code = current_user.postal_code

    @country = current_user.country || User.guess_user_country(request.remote_ip)
  end

  # POST /packages
  # POST /packages.json
  def create
    authorize! :create, Package
    @package = Package.new(package_params)
    @package.shippee = current_user

    @save_address = params[:save_address]
    if params[:save_address].to_s == '1'
      current_user.update_attributes(
        :name => @package.ship_to_name,
        :address => @package.ship_to_address,
        :city => @package.ship_to_city,
        :state => @package.ship_to_state,
        :country => @package.ship_to_country,
        :postal_code => @package.ship_to_postal_code,
      )
    end

    respond_to do |format|
      if set_package_dimensions && @package.save
        admins = User.where(:user_type => User::ADMIN).all
        admins.each do |admin|
          Mailer.notification_email(admin, @package, '[Administrator] Shippee has submitted a package', 'admin_shippee_submitted').deliver
        end
        auto_match_shipper

        format.html { redirect_to @package, notice: 'Package was successfully created.' }
        format.json { render action: 'show', status: :created, location: @package }
      else
        format.html { render action: 'new' }
        format.json { render json: @package.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /packages/1/cancel
  def cancel
    authorize! :delete, @package

    if !@package.cancelable?
      return head :bad_request
    end

    if @package.shipper
      Mailer.notification_email(@package.shipper, @package, 'Package canceled', 'shippee_canceled').deliver
    end
    @package.destroy

    respond_to do |format|
      format.html { redirect_to packages_url }
      format.json { head :no_content }
    end
  end

  # GET /packages/shipping_estimate.json
  def shipping_estimate
    @package = Package.new(package_params)
    # HACKHACKHACK: don't validate shipping estimate (as we're doing that here)
    @package.instance_variable_set('@new_record', false)

    if set_package_dimensions && @package.valid?
      if @package.origin_country == 'United States'
        render json: {:estimates => USPS.get_shipping_estimate(@package)}
      else
        render json: Package::COUNTRY_DATA[@package.origin_country]
      end
    else
      head :unprocessable_entity
    end
  end

  def set_package_dimensions
    size_group = true
    if package_params['size_group'] != "custom" &&
       size_group = Package::SHIPPING_SIZES[package_params['size_group']]
      @package[:length_in] = size_group[:length_in]
      @package[:width_in]  = size_group[:width_in]
      @package[:height_in] = size_group[:height_in]
    else
      @package.errors[:package_size] << 'is required'
    end
    return !size_group.nil?
  end

  # POST /packages/1/shippee_action
  def shippee_action
    authorize! :update, @package

    case @package.state
    when Package::STATE_SUBMITTED
      # if !@package.shipper.nil?
      #   if params[:submit] == 'accept'
      #     @package.state += 1
      #     Mailer.notification_email(@package.shipper, @package, 'User accepted', 'shippee_accepted').deliver
      #   elsif params[:submit] == 'decline'
      #     @package.shipper = nil
      #     Mailer.notification_email(@package.shipper, @package, 'User declined', 'shippee_declined').deliver
      #   end
      # end
    when Package::STATE_SHIPPER_MATCHED
      if params[:submit] == 'ordered'
        @package.shippee_tracking = ''
        Mailer.notification_email(@package.shipper, @package, 'Package ordered', 'shippee_ordered').deliver
      elsif params[:submit] == 'shipped'
        if params[:tracking_carrier] == 'Other'
          params[:tracking_carrier] = params[:tracking_carrier_other]
        end
        flash[:tracking_number] = params[:tracking_number]
        flash[:tracking_carrier] = params[:tracking_carrier]
        if params[:tracking_number].blank? || params[:tracking_carrier].blank?
          flash[:error] = 'Please provide both tracking number and carrier.'
        else
          @package.shippee_tracking = params[:tracking_number]
          @package.shippee_tracking_carrier = params[:tracking_carrier]
          Mailer.notification_email(@package.shipper, @package, 'Package shipped', 'shippee_sent').deliver
        end
      end
    when Package::STATE_SHIPPER_RECEIVED
      if @package.shipping_estimate_confirmed
        if @package.shipping_class.nil? && params[:submit] == 'submit'
          if flash[:estimates][params[:shipping_class]].nil?
            flash[:error] = 'Invalid shipping class.'
          else
            @package.shipping_class = params[:shipping_class]
            @package.shipping_estimate = flash[:estimates][@package.shipping_class]
          end
        elsif !@package.shipping_estimate.nil? && (token = params[:stripeToken])
          total_cost = @package.shipping_estimate_cents
          # Add 20% service fee if no credits are available
          if current_user.referral_credits == 0
            total_cost = (total_cost*6 + 1) / 5
          end
          if txn = create_transaction(token, total_cost)
            @package.state += 1
            txn.save
            Mailer.notification_email(@package.shipper, @package, 'Payment accepted', 'shippee_paid').deliver

            if current_user.referrer &&
               !Package.where(:shippee => current_user, :state => [Package::STATE_SHIPPEE_PAID, Package::STATE_COMPLETED]).first
              ref = current_user.referrer
              ref.update_attributes(:referral_credits => ref.referral_credits + 1)
              Mailer.notification_email(ref, @package, 'New referral credit', 'referral_credit', false).deliver
            end
          end
        elsif !@package.custom_shipping
          @package.shipping_class = @package.shipping_estimate = nil
        end
      end
    when Package::STATE_SHIPPEE_PAID
      if !@package.shippee_tracking.nil? && params[:submit] == 'received'
        @package.state += 1
        Mailer.notification_email(@package.shipper, @package, 'Package received', 'shippee_received').deliver
      end
    when Package::STATE_COMPLETED
      if @package.feedback.nil?
        @package.feedback = Feedback.new(:package => @package, :text => params[:text])
        @package.feedback.save
      end
    end

    if !@package.save
      flash[:error] = 'Error processing your request.'
    end

    redirect_to package_path
  end

  # POST /packages/1/shipper_action
  def shipper_action
    authorize! :update, @package

    case @package.state
    when Package::STATE_SUBMITTED
      if @package.shipper.nil?
        if params[:submit] == 'accept'
          @package.shipper = current_user
          @package.state += 1
          Mailer.notification_email(@package.shippee, @package, 'Please ship your item to us', 'shipper_found').deliver
        end
      end
    when Package::STATE_SHIPPER_MATCHED
      if !@package.shippee_tracking.nil? && params[:submit] == 'received'
        @package.state += 1
      end
    when Package::STATE_SHIPPER_RECEIVED
      if !@package.shipping_estimate_confirmed
        if params[:submit] == 'submit'
          params[:is_envelope] ||= 0
          @package.update(params.permit :length_in, :width_in, :height_in, :is_envelope, :weight_lb)
          if @package.valid?
            if params[:photo_upload].nil?
              flash[:error] = 'You must provide a photo.'
            else
              Photo.where(:package => @package, :photo_type => 'photo').destroy_all
              if create_photo(params[:photo_upload])
                if @package.origin_country == 'United States'
                  flash[:estimates] = USPS.get_shipping_estimate(@package)
                else
                  flash[:estimates] = {}
                end
                @package.custom_shipping = flash[:estimates].empty?
              else
                flash[:error] = 'Invalid photo provided. Make sure you selected the right file.'
              end
            end
          end
        elsif params[:submit] == 'accept'
          flash[:shipping_class] = params[:shipping_class]
          flash[:shipping_estimate] = params[:shipping_estimate]
          if @package.custom_shipping && (params[:shipping_class].blank? || params[:shipping_estimate].blank?)
            flash[:error] = 'Manual shipping estimate must be completed.'
            flash[:estimates] = {} # so it skips the entering details step
          else
            if !params[:shipping_class].blank? && !params[:shipping_estimate].blank?
              @package.shipping_class = params[:shipping_class]
              @package.shipping_estimate = params[:shipping_estimate]
              if @package.shipping_estimate.nil? || @package.shipping_estimate <= 0
                flash[:error] = 'Must provide a valid shipping estimate.'
                flash[:estimates] = {}
              else
                @package.shipping_estimate_cents = ISO4217::Currency::ExchangeBank.instance.exchange(
                  @package.shipping_estimate_cents, Package::COUNTRY_DATA[@package.origin_country][:currency], 'USD')
              end
            end
            if !flash[:error]
              @package.shipping_estimate_confirmed = true
              Mailer.notification_email(@package.shippee, @package, 'We have received your package', 'shipper_received').deliver
            end
          end
        elsif params[:submit] == 'back'
          @package.custom_shipping = false
        end
      end
    when Package::STATE_SHIPPEE_PAID
      if @package.shipper_tracking.nil? && params[:submit] == 'submit'
        flash[:shipping_cost] = params[:shipping_cost]
        flash[:tracking_number] = params[:tracking_number]
        flash[:tracking_carrier] = params[:tracking_carrier]
        if params[:shipping_cost].blank? || params[:tracking_number].blank? || params[:tracking_carrier].blank?
          flash[:error] = 'All fields below must be filled out.'
        else
          shipping_cost = Float(params[:shipping_cost]) rescue nil
          shipping_cost_cents = ((shipping_cost||0) * 100).round

          shipping_cost_cents = ISO4217::Currency::ExchangeBank.instance.exchange(
            shipping_cost_cents, Package::COUNTRY_DATA[@package.origin_country][:currency], 'USD')

          actual_charge = shipping_cost_cents
          if @package.shippee.referral_credits == 0
            actual_charge = (actual_charge*6 + 1) / 5
          end

          if shipping_cost.nil? || actual_charge < @package.transaction.preauth_charge_cents/2 ||
             actual_charge > @package.transaction.preauth_charge_cents
            flash[:error] = "Invalid shipping cost provided."
          elsif params[:receipt_upload].nil?
            flash[:error] = 'You must provide a receipt.'
          elsif !create_photo(params[:receipt_upload], 'receipt')
            flash[:error] = 'Invalid receipt provided. Make sure you selected the right file.'
          else
            if txn = finish_transaction(actual_charge)
              @package.shipping_estimate_cents = shipping_cost_cents
              @package.shipper_tracking = params[:tracking_number] || ''
              @package.shipper_tracking_carrier = params[:tracking_carrier] || ''
              txn.save

              # Deduct a referral credit if one was used
              if @package.shippee.referral_credits > 0
                @package.shippee.update_attributes(:referral_credits => @package.shippee.referral_credits - 1)
              end

              Mailer.notification_email(@package.shippee, @package, 'We have sent your package', 'shipper_sent').deliver
            end
          end
        end
      end
    end

    if !@package.save
      flash[:error] = '<br />' + @package.errors.full_messages.map { |m| ' - ' + m }.join('<br />')
    end

    redirect_to package_path
  end

  # POST /packages/1/admin_action
  def admin_action
    authorize! :admin, @package

    case @package.state
    when Package::STATE_SUBMITTED
      @package.shipper_id = params[:shipper][:shipper_id]
      @package.state = @package.state + 1
      Mailer.notification_email(@package.shipper, @package, 'Package for you!', 'shipper_matched').deliver
      if !@package.save
        flash[:error] = '<br />' + @package.errors.full_messages.map { |m| ' - ' + m }.join('<br />')
      end
    end

    redirect_to package_path
  end

  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def package_params
      params.require(:package).permit [
        :length_in,
        :width_in,
        :height_in,
        :weight_lb,
        :value,
        :is_envelope,
        :description,
        :origin_country,
        :ship_to_name,
        :ship_to_address,
        :ship_to_state,
        :ship_to_city,
        :ship_to_country,
        :ship_to_postal_code,
        :special_instructions,
        :size_group,
      ]
    end

    def auto_match_shipper
      best_match = nil
      best_count = nil

      User.where(:user_type => User::SHIPPER, :country => @package.origin_country).each do |u|
        count = 0
        Package.where(:shipper => u).each do |p|
          # Shipper is done once he enters tracking information, pretty much.
          if p.shipper_tracking.nil?
            count += 1
          end
        end

        if best_match.nil? || count < best_count
          best_match = u
          best_count = count
        end
      end

      unless best_match.nil?
        @package.update_attributes(:shipper => best_match, :state => @package.state + 1)
        Mailer.notification_email(best_match, @package, 'Package for you!', 'shipper_matched').deliver
      end
    end

    def create_photo(data, type = 'photo')
      # Check if it's an image with a valid extension
      return nil if !data.content_type['image/'] || !data.original_filename['.']

      p = Photo.new(
        :package => @package,
        :photo_type => type,
        :file_type => data.original_filename.split('.').last
      )
      p.save # generate new ID

      begin
        File.open(p.file_name, 'wb') do |file|
          file.write(data.read)
        end
      rescue => e
        p.delete
        return nil
      end

      return p
    end

    # Accept payment with Stripe
    def create_transaction(card_token, amount)
      Stripe.api_key = STRIPE_CONFIG["SECRET_KEY"]

      begin
        # Add 50% (with rounding)
        preauth_amount = (amount*3 + 1)/2
        charge = Stripe::Charge.create(
          :amount => preauth_amount,
          :currency => 'usd',
          :card => card_token,
          :capture => false,
          :metadata => { 'package_id' => @package.id }
        )
        return Transaction.new(:package => @package, :charge_id => charge.id, :preauth_charge_cents => preauth_amount)
      rescue Stripe::CardError => e
        # Card was declined
        body = e.json_body
        err  = body[:error]
        flash[:error] = "Card was declined (#{err[:message]})"
      rescue => e
        flash[:error] = "Error connecting to Stripe. Please try again."
        Mailer.error_email(current_user, request.original_url, e.message).deliver
      end

      return nil
    end

    # Retrieve previous pre-authorized payment; actually charge it.
    def finish_transaction(amount)
      Stripe.api_key = STRIPE_CONFIG["SECRET_KEY"]

      begin
        charge = Stripe::Charge.retrieve(@package.transaction.charge_id)
        charge.capture(:amount => amount)
        txn = @package.transaction
        txn.final_charge_cents = amount
        return txn
      rescue => e
        flash[:error] = "Error processing shipping cost (#{e.message}). Please try again."
        Mailer.error_email(current_user, request.original_url, e.message).deliver
      end

      return nil
    end
end
