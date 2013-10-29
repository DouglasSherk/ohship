class User < ActiveRecord::Base
  after_create :send_welcome_email

  attr_accessor :is_new

  SHIPPEE = 0
  SHIPPER = 1

  validates :user_type, :inclusion => { :in => [SHIPPEE, SHIPPER] }

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  devise :omniauthable, :omniauth_providers => [:facebook]

  # For OmniAuth Facebook authentication.
  #attr_accessible :provider, :uid, :name

  def self.find_for_facebook_oauth(auth, signed_in_resource = nil)
    user = User.where(:provider => auth.provider, :uid => auth.uid).first
    unless user
      user = User.create(name: auth.extra.raw_info.name,
                         provider: auth.provider,
                         uid: auth.uid,
                         email: auth.info.email,
                         password: Devise.friendly_token[0,20])
      user.is_new = true
    end
    user
  end

  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session["devise.facebook_data"] && session["devise.facebook_data"]["extra"]["raw_info"]
        user.email = data["email"] if user.email.blank?
      end
    end
  end

  def self.guess_user_country
    geoip = GeoIP.new("#{Rails.root}/db/GeoIP.dat")
    remote_ip = request.remote_ip
    if remote_ip != "127.0.0.1"
      location = geoip.country(remote_ip)
      if location != nil
        return location.country_name
      end
    else
      return 'Canada'
    end
  end

  private
    def send_welcome_email
      Mailer.welcome_email(self).deliver
    end
end
