class Mailer < PostageApp::Mailer
  include Devise::Mailers::Helpers
  default from: 'OhShip <no-reply@ohship.me>'

  def confirmation_instructions(record, token, opts = {})
    @token = token
    devise_mail(record, :confirmation_instructions, opts)
  end

  def reset_password_instructions(record, token, opts = {})
    @token = token
    devise_mail(record, :reset_password_instructions, opts)
  end

  def unlock_instructions(record, token, opts = {})
    @token = token
    devise_mail(record, :unlock_instructions, opts)
  end

  def welcome_email(user)
    @user = user
    mail to: user.email, subject: 'Welcome to OhShip!'
  end

  def notification_email(user, package, subject, name)
    @user = user
    @package = package
    mail to: user.email, subject: subject + " (#{package.description})",
         template_path: 'mailer/notifications', template_name: name
  end
end
