class User < ActiveRecord::Base
  SHIPPER = 0
  SHIPPEE = 1

  validates :user_type, :inclusion => { :in => SHIPPER..SHIPPEE }

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
end
