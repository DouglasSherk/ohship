class Mailer < PostageApp::Mailer
  include Devise::Mailers::Helpers
  add_template_helper PackagesHelper

  EMAIL = 'hello@ohship.me'
  default from: "OhShip <#{EMAIL}>"

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

  def error_email(user, url, error_message)
    @user = user
    @url = url
    @message = error_message
    mail to: EMAIL, subject: 'An unhandled error occurred'
  end

  def notification_email(user, package, subject, name, with_description = true)
    @user = user
    @package = package
    mail to: user.email, subject: subject + (with_description ? " (#{package.description})" : ''),
         template_path: 'mailer/notifications', template_name: name
  end
end
