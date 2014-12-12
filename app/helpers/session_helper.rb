module SessionHelper

  private

    def log_in(user)
      session[:user_id] = user.id
      session[:collection_filter] = false
    end

    def current_user
      @current_user ||= User.find_by(id: session[:user_id])
    end

    def logged_in?
      !current_user.nil?
    end

    def log_out
      session.delete(:user_id)
      session.delete(:collection_filter)
      current_user = nil
      @current_user = nil
    end

end
