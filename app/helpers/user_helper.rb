module UserHelper

  private

    def account_valid?
      if params[:magic_account].empty?
        flash_message :danger, "Magic account name cannot be blank."
        return false
      elsif params[:magic_account] !~ /\A[\w+\-.]+\z/i
        flash_message :danger, "Magic account name not valid."
        return false
      elsif params[:magic_account].length < 3
        flash_message :danger, "Magic account name must contain at least 3 characters."
        return false
      else
        return true
      end
    end

    def codes_valid?
      if params[:bot_code].empty? || params[:user_code].empty?
        flash_message :danger, "MTGO codes cannot be blank."
        return false
      elsif params[:bot_code].length < 6 || params[:user_code].length < 6
        flash_message :danger, "MTGO codes must contain at least 6 characters."
        return false
      else
        return true
      end
    end

    def max_accounts?
      if current_user.magic_accounts.count == 10
        flash_message :danger, "You may only have 10 magic accounts."
        return true
      else
        return false
      end
    end

    def email_valid?
      if params[:email].empty?
        flash_message :danger, "Email address cannot be blank."
        return false
      elsif params[:email] !~ /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
        flash_message :danger, "Email address not valid."
        return false
      else
        return true
      end
    end

    def email_available?
      if User.where(email: params[:email].downcase).any?
        flash_message :danger, "Email address already in use."
        return false
      else
        return true
       end
    end

    def email_registered?
      if User.where(email: params[:email].downcase).empty?
        flash_message :danger, "No account exists with that email."
        return false
      else
        return true
       end
    end


    def password_valid?
      if params[:password].length < 8
        flash_message :danger, "Password must contain at least 8 characters."
        return false
      elsif params[:password].length > 255
        flash_message :danger, "Password must contain no more than 255 characters."
        return false
      else
        return true
      end
    end

    def confirm_password?
      if params[:password] != params[:password_confirmation]
        flash_message :danger, "Password and confirmation must match."
        return false
      else
        return true
      end
    end

    def authenticate_password?(user, password)
	  if password.blank?
        flash_message :danger, "Incorrect password."
        return false
	  end       
      if user.authenticate(password)
        return true
      else
        flash_message :danger, "Incorrect password."
        return false
      end
    end

    def associated_account?
      if @user.magic_accounts.map {|account| account.name }.include?(params[:magic_account])
        return true
      else
        flash_message :danger, "You have not added this account."
        return false
      end
    end


end
