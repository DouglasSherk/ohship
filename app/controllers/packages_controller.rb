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
      if token = params[:stripeToken]
        # TODO: verify token, add transaction
        @package.transaction_id = 1234
        @package.state += 1
        Mailer.notification_email(@package.shipper, @package, 'Payment accepted', 'shippee_paid').deliver
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
      if @package.shipping_estimate.nil?
        if params[:submit] == 'submit'
          # TODO: verify & get shipping estimate
          flash[:shipping_estimate] = 12.34
        elsif params[:submit] == 'accept' && params[:shipping_estimate]
          @package.shipping_estimate = params[:shipping_estimate].to_f
          Mailer.notification_email(@package.shippee, @package, 'Shipper received package', 'shipper_received').deliver
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
      flash[:error] = 'Error processing your request.'
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
