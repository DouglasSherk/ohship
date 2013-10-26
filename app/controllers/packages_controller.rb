if Rails.env == 'development'
  require_dependency 'usps'
else
  require 'usps'
end

class PackagesController < ApplicationController
  load_and_authorize_resource :except => [:index, :new, :create]
  skip_authorize_resource :only => [:shippee_action, :shipper_action]

  before_filter :authenticate_user!

  # GET /packages
  # GET /packages.json
  def index
    @packages = Package.all.select { |package| can? :read, package }
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

  # DELETE /packages/1
  # DELETE /packages/1.json
  def destroy
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
          @package.shipping_class = params[:shipping_class]
          @package.shipping_estimate = flash[:estimates][@package.shipping_class]
        elsif !@package.shipping_estimate.nil? && (token = params[:stripeToken])
          # TODO: verify token, add transaction
          @package.transaction_id = 1234
          @package.state += 1
          Mailer.notification_email(@package.shipper, @package, 'Payment accepted', 'shippee_paid').deliver
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
            flash[:estimates] = USPS.get_shipping_estimate(@package)
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
        @package.shipper_tracking = params[:tracking_number] || ''
        @package.shipper_tracking_carrier = params[:tracking_carrier] || ''
        Mailer.notification_email(@package.shippee, @package, 'Shipper sent package', 'shipper_sent').deliver
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
end
