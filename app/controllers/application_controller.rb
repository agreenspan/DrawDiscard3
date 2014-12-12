class ApplicationController < ActionController::Base
  include ApplicationHelper
  include UserHelper
  include SessionHelper
  include MagicSetHelper
  include MagicCardHelper

  before_action :account_disabled?, except: [sessions_controller: :sign_out]
  before_action :instance_user

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  rescue_from ActionController::InvalidAuthenticityToken do 
    flash_message :warning, "Session timed out due to inactivity."
    redirect_to '/'
  end

  def instance_user
    @user = current_user
  end

  def account_disabled?
    if logged_in?
      if current_user.account_status == "disabled"
        flash_message :danger, "Account disabled. Please contact support."
        log_out
        redirect_to '/' and return
      end
    end
  end

end
