# Preview all emails at http://localhost:3000/rails/mailers/draw_discard_mailer
class DrawDiscardMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/draw_discard_mailer/confirmation
  def confirmation
    DrawDiscardMailer.confirmation
  end

  # Preview this email at http://localhost:3000/rails/mailers/draw_discard_mailer/forgot_password
  def forgot_password
    DrawDiscardMailer.forgot_password
  end

end
