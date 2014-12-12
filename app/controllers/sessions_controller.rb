class SessionsController < ApplicationController

  def sign_in
    redirect_to user_collection_path(current_user) and return if logged_in?
    errors = false
    if request.post?
      #params data check
      errors = true unless email_valid?
      errors = true unless email_registered?
      errors = true unless password_valid?
      redirect_to action: 'sign_in', status: 303 and return if errors == true
      @user = User.find_by(email: params[:email].downcase)
      errors = true unless authenticate_password?(@user, params[:password])
      redirect_to action: 'sign_in', status: 303 and return if errors == true
      log_in(@user)
      redirect_to :back and return
    end
  end

  def sign_out
    log_out
    redirect_to '/' and return 
  end

  def update
    if params.has_key?('collection_filter')
      session[:collection_filter] = ( params[:collection_filter] == "true" ? true : false )
    end
    render :nothing => true
  end

end
