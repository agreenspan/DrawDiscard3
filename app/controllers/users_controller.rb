class UsersController < ApplicationController
before_action :check_user?, except: [:create, :register, :reset_password, :confirmation]
before_action :mtgo_configured?, only: [:collection, :transactions, :transfers]

### Methods available when not logged in

  def create
    #params data checks
    email_valid?
    email_available?
    password_valid?
    confirm_password?
    @user = User.new(email: params[:email], password: params[:password], password_confirmation: params[:password_confirmation])
    if @user.save
      flash_message :success, "Welcome to DrawDiscard!"
      log_in(@user)
      DrawDiscardMailer.confirmation(@user).deliver
      flash_message :info, "Setup, Step 1: Confirm your email."
      redirect_to confirmation_path and return
    else
      redirect_to register_path and return
    end
  end

  def register
    redirect_to user_collection_path(@user) and return if @user.present?
  end

  def reset_password
    redirect_to user_change_password_path(@user) and return if @user.present?
    if request.post?
      errors = false
      case params[:commit]
        when "Send Password Reset Email", "Re-send Password Reset Email"
          errors = true unless email_valid?
          errors = true unless email_registered?
          redirect_to reset_password_path and return if errors == true
          user = User.find_by(email: params[:email])
          DrawDiscardMailer.reset_password(user).deliver
          flash_message :success, "Password reset email sent."
          redirect_to reset_password_path(email: user.email, reset_view: true) and return
        when "Reset Password"
          errors = true unless email_valid?
          errors = true unless email_registered?
          errors = true if field_empty?("Reset code", params[:reset_code])
          errors = true unless password_valid?
          errors = true unless confirm_password?
          redirect_to reset_password_path(reset_view: true) and return if errors == true
          user = User.find_by(email: params[:email])
          if user.confirmation_code != params[:reset_code]
            flash_message :danger, "Incorrect reset code."
            redirect_to confirmation_path(reset_view: true) and return
          end
          user.update_attributes(password: params[:password], password_confirmation: params[:password_confirmation], confirmation_code: "")
          flash_message :success, "Password successfully reset."
          log_in(user)
          redirect_to '/' and return
        else
          redirect_to reset_password_path and return
      end
    end
  end

  def confirmation
    redirect_to user_collection_path(@user) and return if @user.present? && @user.confirmed
    if request.post? || params[:email_confirmation]
      errors = false
      case params[:commit]
        when "Re-send Confirmation Email"
          #params data check
          errors = true unless email_valid?
          errors = true unless email_registered?
          redirect_to confirmation_path and return if errors == true
          user = User.find_by(email: params[:email])
          if user.confirmed
            flash_message :danger, "User already confirmed."
            redirect_to '/' and return
          end
          DrawDiscardMailer.confirmation(user).deliver
          flash_message :success, "Confirmation email re-sent."
          redirect_to confirmation_path and return
        when "Confirm Email" 
          #params data check
          errors = true unless email_valid?
          errors = true unless email_registered?
          errors = true if field_empty?("Confirmation code", params[:confirmation_code])
          redirect_to confirmation_path and return if errors == true
          user = User.find_by(email: params[:email])
          if user.confirmed
            flash_message :danger, "User already confirmed."
            redirect_to '/' and return
          end
          if user.confirmation_code != params[:confirmation_code]
            flash_message :danger, "Incorrect confirmation code."
            redirect_to confirmation_path and return
          end
          user.update_attribute(:confirmation_code, "")
          user.update_attribute(:confirmed, true)
          flash_message :success, "Email confirmed."         
          if user.present?
            flash_message :info, "Setup, Step 2: Add a magic account."
            redirect_to user_mtgo_accounts_path(user) and return if user == @user
          else
            redirect_to sign_in_path and return
          end
        else
          redirect_to confirmation_path and return
      end
    end
  end

### Methods available only when logged in

  def update
    errors = false
    case params[:update_type]
      when "change_password"
        #params data check
        errors = true unless authenticate_password?(@user, params[:old_password])
        errors = true unless password_valid?
        errors = true unless confirm_password?
        redirect_to user_change_password_path(@user) and return if errors == true
        @user.update_attributes(password: params[:password], password_confirmation: params[:password_confirmation])
        flash_message :success, "Password Changed"
        redirect_to user_collection_path(@user) and return
      when "add_mtgo_account"
        #params data check
        errors = true if max_accounts?
        errors = true unless account_valid?
        errors = true unless authenticate_password?(@user, params[:password])
        if MagicAccount.where(user_id: @user.id, name: params[:magic_account]).any?
          errors = true
          flash_message :danger, "You've already added that account."
        end
        redirect_to user_mtgo_accounts_path(@user) and return if errors == true
        MagicAccount.create(user_id: @user.id, name: params[:magic_account])
        flash_message :success, "#{params[:magic_account]} added."
        if @user.user_code.blank? && @user.bot_code.blank?
          flash_message :info, "Setup, Step 3: Set up your MTGO codes."
          redirect_to user_mtgo_codes_path(@user) and return
        else
          redirect_to user_mtgo_accounts_path(@user) and return
        end
      when "remove_mtgo_account"
        errors = true unless account_valid?
        errors = true unless authenticate_password?(@user, params[:password])
        unless MagicAccount.where(user_id: @user.id, name: params[:magic_account]).any?
          errors = true
          flash_message :danger, "You don't have that account added."
        end
        redirect_to user_mtgo_accounts_path(@user) and return if errors == true
        account = MagicAccount.where(user_id: @user.id, name: params[:magic_account]).first
        if account.in_queue?
          flash_message :danger, "Account cannot be removed while in the trade queue."
          redirect_to user_mtgo_accounts_path(@user) and return
        end
        account.stocks.where(status: ["depositing", "offline"]).each do |stock|
          stock.transactions.each do |transaction|
            transaction.update_attribute(:stock_id, nil)
          end
          unless stock.destroy
            flash_message :danger, "Something went wrong with the stocks removal."
            redirect_to user_mtgo_accounts_path(@user) and return
          end
        end
        if account.stocks.any?
          flash_message :warning, "Some stocks were left over. Please contact support."
        end
        if account.destroy
          flash_message :info, "Magic Account removed."
        else
          flash_message :danger, "Something went wrong with the account removal."
        end
        redirect_to user_mtgo_accounts_path(@user) and return
      when "mtgo_codes"
        errors = true unless codes_valid?
        errors = true unless password_valid?
        errors = true unless authenticate_password?(@user, params[:password])
        if @user.in_queue?
          flash_message :danger, "MTGO codes cannot be changed while in the trade queue."
          errors = true
        end
        redirect_to user_mtgo_codes_path(@user) and return if errors == true
        @user.update_attribute(:bot_code, params[:bot_code])
        @user.update_attribute(:user_code, params[:user_code])
        flash_message :success, "MTGO codes set."
        redirect_to user_collection_path(@user) and return
      else
        redirect_to user_collection_path(@user) and return
    end

  end

  def collection
  end

  def transactions
  end

  def transfers
  end

  def change_password
  end

  def mtgo_accounts
    @magic_accounts = @user.magic_accounts
  end

  def mtgo_codes
    @no_codes = true if (@user.user_code.blank? || @user.bot_code.blank?)
    if request.post?
      error = false
      errors = true unless password_valid?
      errors = true unless authenticate_password?(@user, params[:password])
      redirect_to user_mtgo_codes_path(@user) and return if errors == true
      @show_codes = true
      render "mtgo_codes"
    end
  end

  private

  def check_user?
    unless @user.present?
      flash_message :danger, "Please sign in."
      redirect_to sign_in_path and return
    end
    unless User.find_by(id: params[:id]) || User.find_by(id: params[:user_id]) == @user
      flash_message :danger, "Unauthorized user."
      redirect_to '/' and return  
    end
    unless @user.confirmed
      flash_message :info, "Setup,  Step 1: Confirm your email."
      redirect_to confirmation_path and return
    end
  end

  def mtgo_configured?
    unless @user.magic_accounts.any?
      flash_message :info, "Setup, Step 2: Add a magic account."
      redirect_to user_mtgo_accounts_path(@user) and return
    end
    unless !@user.user_code.blank? && !@user.bot_code.blank?
      flash_message :info, "Setup, Step 3: Set up your MTGO codes."
      redirect_to user_mtgo_codes_path(@user) and return
    end
  end

end
