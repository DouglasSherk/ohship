if Rails.env == 'development'
  require_dependency 'usps'
else
  require 'usps'
end

require 'stripe'

class PackagesController < ApplicationController
  load_and_authorize_resource :except => [:index, :new, :create]
  skip_authorize_resource :only => [:cancel, :shippee_action, :shipper_action]

  before_filter :authenticate_user!

  # GET /packages
  # GET /packages.json
  def index
    @packages = Package.all.select { |package| can? :read, package }

    if current_user.user_type == User::SHIPPER
      @packages = @packages.select { |package| package.origin_country == current_user.country }
    end
  end

  # GET /packages/1
  # GET /packages/1.json
  def show
    # Load shipping estimates from USPS
    if current_user.user_type == User::SHIPPEE &&
       @package.state == Package::STATE_SHIPPER_RECEIVED &&
       @package.shipping_estimate_confirmed &&
       @package.shipping_estimate.nil?
      flash[:estimates] ||= USPS.get_shipping_estimate(@package)
    end

    @photos = @package.photos.where(:photo_type => 'photo')
    @receipt = @package.photos.where(:photo_type => 'receipt').first
  end

  # GET /packages/new
  def new
    authorize! :create, Package
    @package = Package.new
  end

  # POST /packages
  # POST /packages.json
  def create
    authorize! :create, Package
    @package = Package.new(package_params)
    @package.shippee = current_user

    respond_to do |format|
      if @package.save
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
    p = Package.new(package_params)
    # HACKHACKHACK: don't validate shipping estimate (as we're doing that here)
    p.instance_variable_set('@new_record', false)

    if p.valid?
      # Get estimates, rename with display names
      render json: Hash[USPS.get_shipping_estimate(p).map { |k, v| [Package::SHIPPING_CLASSES[k], v] }.reverse]
    else
      head :unprocessable_entity
    end
  end

  # POST /packages/1/shippee_action
  def shippee_action
    authorize! :update, @package

    case @package.state
    when Package::STATE_SUBMITTED
      if !@package.shipper.nil?
        if params[:submit] == 'accept'
          @package.state += 1
          Mailer.notification_email(@package.shipper, @package, 'User accepted', 'shippee_accepted').deliver
        elsif params[:submit] == 'decline'
          @package.shipper = nil
          Mailer.notification_email(@package.shipper, @package, 'User declined', 'shippee_declined').deliver
        end
      end
    when Package::STATE_SHIPPER_MATCHED
      if params[:submit] == 'shipped'
        @package.shippee_tracking = params[:tracking_number]
        @package.shippee_tracking_carrier = params[:tracking_carrier]
        Mailer.notification_email(@package.shipper, @package, 'Package sent', 'shippee_sent').deliver
      end
    when Package::STATE_SHIPPER_RECEIVED
      if @package.shipping_estimate_confirmed
        if @package.shipping_class.nil? && params[:submit] == 'submit' && flash[:estimates]
          if flash[:estimates][params[:shipping_class]].nil?
            flash[:error] = 'Invalid shipping class.'
          else
            @package.shipping_class = params[:shipping_class]
            @package.shipping_estimate = flash[:estimates][@package.shipping_class]
          end
        elsif !@package.shipping_estimate.nil? && (token = params[:stripeToken])
          if txn = create_transaction(token, @package.shipping_estimate_cents)
            @package.state += 1
            Mailer.notification_email(@package.shipper, @package, 'Payment accepted', 'shippee_paid').deliver
            txn.save
          end
        else
          @package.shipping_class = @package.shipping_estimate = nil
        end
      end
    when Package::STATE_SHIPPEE_PAID
      if !@package.shippee_tracking.nil? && params[:submit] == 'received'
        @package.state += 1
        Mailer.notification_email(@package.shippee, @package, 'Package received', 'shippee_received').deliver
      end
    when Package::STATE_COMPLETED
      if @package.feedback.nil? && params[:text] && params[:text] != ''
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
          Mailer.notification_email(@package.shippee, @package, 'Shipper found', 'shipper_found').deliver
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
            elsif create_photo(params[:photo_upload])
              flash[:estimates] = USPS.get_shipping_estimate(@package)
            else
              flash[:error] = 'Invalid photo provided. Make sure you selected the right file.'
            end
          end
        elsif params[:submit] == 'accept'
          @package.shipping_estimate_confirmed = true
          Mailer.notification_email(@package.shippee, @package, 'Shipper received package', 'shipper_received').deliver
        elsif params[:submit] == 'back'
          @package.shipping_estimate = nil
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
          if shipping_cost.nil? || shipping_cost_cents < @package.transaction.preauth_charge_cents/2 ||
             shipping_cost_cents > @package.transaction.preauth_charge_cents
            flash[:error] = "Invalid shipping cost provided."
          elsif params[:receipt_upload].nil?
            flash[:error] = 'You must provide a receipt.'
          elsif !create_photo(params[:receipt_upload], 'receipt')
            flash[:error] = 'Invalid receipt provided. Make sure you selected the right file.'
          else
            if txn = finish_transaction(shipping_cost_cents)
              @package.shipping_estimate_cents = shipping_cost_cents
              @package.shipper_tracking = params[:tracking_number] || ''
              @package.shipper_tracking_carrier = params[:tracking_carrier] || ''
              Mailer.notification_email(@package.shippee, @package, 'Shipper sent package', 'shipper_sent').deliver
              txn.save
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
        :special_instructions
      ]
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
        File.open(Rails.root.join('uploads', p.id.to_s + '.' + p.file_type), 'wb') do |file|
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
      # TODO: Put the real token in an environment variable
      Stripe.api_key = 'sk_test_1G0fj6LjMEBRCkvGQvg70meT'

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
      # TODO: Put the real token in an environment variable
      Stripe.api_key = 'sk_test_1G0fj6LjMEBRCkvGQvg70meT'

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
