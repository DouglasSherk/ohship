class Presignup < ActiveRecord::Base
  validates :email, :format => { :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, :message => "You must enter a valid email." },
                    :presence => { :message => "You must enter an email."},
                    :uniqueness => { :message => "This email has already been entered." }
end
