class DrawDiscardMailer < ActionMailer::Base
  default from: "drawdiscard@gmail.com"
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.draw_discard_mailer.confirmation.subject
  #
  def confirmation(user)
    @user = user
    @user.generate_confirmation_code
    mail(to: @user.email, subject: "Confirmation") do |f|
      f.html
    end

  end

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.draw_discard_mailer.forgot_password.subject
  #
  def reset_password(user)
    @user = user
    @user.generate_confirmation_code
    mail(to: @user.email, subject: "Reset Password") do |f|
      f.html
    end
    
  end
end
