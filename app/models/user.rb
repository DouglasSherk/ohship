class User < ActiveRecord::Base
  after_create :send_welcome_email

  SHIPPER = 0
  SHIPPEE = 1

  validates :user_type, :inclusion => { :in => SHIPPER..SHIPPEE }

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  devise :omniauthable, :omniauth_providers => [:facebook]

  # For OmniAuth Facebook authentication.
  #attr_accessible :provider, :uid, :name

  private
    def send_welcome_email
      Mailer.welcome_email(self).deliver
    end
end
