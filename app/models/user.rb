class User < ActiveRecord::Base
  after_create :send_welcome_email
  after_create :set_is_new

  belongs_to :referrer, :class_name => 'User'
  has_many :referrals, :class_name => 'User', :foreign_key => 'referrer_id'

  attr_accessor :is_new

  SHIPPEE = 0
  SHIPPER = 1
  ADMIN = 2

  validates :name, presence: true
  validates :user_type, :inclusion => { :in => [SHIPPEE, SHIPPER, ADMIN] }

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  devise :omniauthable, :omniauth_providers => [:facebook]

  # For OmniAuth Facebook authentication.
  #attr_accessible :provider, :uid, :name

  def self.find_for_facebook_oauth(auth, signed_in_resource = nil, referrer_id = nil)
    user = User.where(:provider => auth.provider, :uid => auth.uid).first
    unless user
      user = User.create(name: auth.extra.raw_info.name,
                         provider: auth.provider,
                         uid: auth.uid,
                         email: auth.info.email,
                         password: Devise.friendly_token[0,20],
                         referrer_id: referrer_id)
    end
    user
  end

  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session["devise.facebook_data"]
        user.email = data["email"] if user.email.blank?
      end
    end
  end

  def self.guess_user_country(remote_ip)
    geoip = GeoIP.new("#{Rails.root}/db/GeoIP.dat")
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
      Mailer.welcome_email(self).deliver if valid?
    end

    def set_is_new
      self.is_new = true
    end
end
