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
    if request.format == 'json'
      @order = []
      total_collection_sql = "
        SELECT COUNT (*) as total
        FROM Magic_Cards 
        WHERE Magic_Cards.disabled = false AND Magic_Cards.id IN (
          SELECT Stocks.magic_card_id
          FROM Stocks
          WHERE Stocks.user_id = #{@user.id}
          GROUP BY Stocks.magic_card_id
          UNION
          SELECT Transactions.magic_card_id
          FROM Transactions
          WHERE Transactions.buyer_id = #{@user.id} AND status = 'buying'
          GROUP BY Transactions.magic_card_id
        )"
      total_records = ActiveRecord::Base.connection.execute(total_collection_sql).first["total"]
      filtered_collection = ActiveRecord::Base.connection.execute(compile_filter_sql)
      filtered_records = filtered_collection.count
      showing = filtered_collection.drop(params[:start].to_i).first(params[:length].to_i).map{|c| c["id"]}
      showing_collection_sql = " 
        SELECT Magic_Cards.id, Magic_Cards.mtgo_id, Magic_Cards.name, Magic_Cards.plain_name, Magic_Cards.foil, Magic_Cards.rarity, Magic_Cards.object_type, Magic_Cards.magic_set_id
        , (Magic_Sets.name) AS set_name, Magic_Sets.code 
        , (SELECT MAX(Transactions.price) FROM Transactions WHERE (Transactions.magic_card_id = Magic_Cards.id AND Transactions.status = 'buying')) AS buying_price 
        , (SELECT MIN(Transactions.price) FROM Transactions WHERE (Transactions.magic_card_id = Magic_Cards.id AND Transactions.status = 'selling')) AS selling_price 
        , (SELECT COUNT(*) FROM Stocks WHERE (Stocks.magic_card_id = Magic_Cards.id AND Stocks.status = 'online' AND Stocks.user_id = #{@user.id})) AS online
        , (SELECT COUNT(*) FROM Stocks WHERE (Stocks.magic_card_id = Magic_Cards.id AND Stocks.status = 'depositing' AND Stocks.user_id = #{@user.id})) AS depositing
        , (SELECT COUNT(*) FROM Stocks WHERE (Stocks.magic_card_id = Magic_Cards.id AND Stocks.status = 'withdrawing' AND Stocks.user_id = #{@user.id})) AS withdrawing
        , (SELECT COUNT(*) FROM Stocks WHERE (Stocks.magic_card_id = Magic_Cards.id AND Stocks.status = 'selling' AND Stocks.user_id = #{@user.id})) AS selling
        , (SELECT COUNT(*) FROM Transactions WHERE (Transactions.magic_card_id = Magic_Cards.id AND Transactions.status = 'buying' AND Transactions.buyer_id = #{@user.id})) AS buying
        FROM Magic_Cards 
        JOIN Magic_Sets ON Magic_Cards.magic_set_id = Magic_Sets.id
        WHERE Magic_Cards.disabled = false AND Magic_Cards.id IN ( #{ ( showing.empty? ? "'0'" : showing.join(', ') ) } ) ORDER BY #{@order[1]} " 
      showing_collection = MagicCard.find_by_sql(showing_collection_sql)
      json = {
        draw: params[:draw].to_i,
        recordsTotal: total_records,
        recordsFiltered: filtered_records,
        data: showing_collection.map do |card|
          rarity = ( card.rarity.present? ? card.rarity : card.object_type)
          [ view_context.link_to( magic_set_magic_card_path( card.code, card.mtgo_id ) ) do
            ( card.name + ( card.foil ? " "+view_context.image_tag("foil.png", height: "30%", title: "Foil") : "" ) ).html_safe
          end,
            view_context.link_to(card.code, magic_set_path( card.code ) ).html_safe,
            "<strong class='#{rarity}-text' title='#{rarity.titleize}'>#{rarity.titleize.chars.first}</strong>".html_safe,
            card.buying_price,
            card.selling_price,
            card.online,
            card.depositing,
            card.withdrawing,
            card.selling,
            card.buying ]
        end 
      }
    else
      @collection_page_override = true
      @filters = Hash.new
      @filters[:on]= Hash.new
      @filters[:on][:on] = false
      @filters[:on][:foil] = true
      @filters[:on][:rarity] = true
      @filters[:on][:collection] = true
      @filters[:on][:set] = false
      @filters[:foil] = Hash.new
      @filters[:foil][:normal] = ""
      @filters[:foil][:foil] = ""
      @filters[:rarity] = Hash.new
      @filters[:rarity][:special] = ""
      @filters[:rarity][:mythic] = ""
      @filters[:rarity][:rare] = ""
      @filters[:rarity][:uncommon] = ""
      @filters[:rarity][:common] = ""
      @filters[:rarity][:planar] = ""
      @filters[:rarity][:pack] = ""
      @filters[:rarity][:vanguard] = ""
      @filters[:rarity][:basic] = 0
      @filters[:collection] = Hash.new
      @filters[:collection][:online] = ["", "DrawDiscard", "DD.png"]
      @filters[:collection][:depositing] = ["", "Depositing", "arrowDD.png"]
      @filters[:collection][:withdrawing] = ["", "Withdrawing", "arrowM.png"]
      @filters[:collection][:selling] = ["", "Selling", "forSale.png"]
      @filters[:collection][:buying] = ["", "Buying", "bids.png"]
      collection_sets_sql = "
        SELECT Magic_Sets.code, Magic_Sets.name
        FROM Magic_Cards JOIN Magic_Sets ON Magic_Cards.magic_set_id = Magic_Sets.id
        WHERE Magic_Cards.id IN (
          SELECT Stocks.magic_card_id
          FROM Stocks
          WHERE Stocks.user_id = #{@user.id}
          GROUP BY Stocks.magic_card_id
          UNION
          SELECT Transactions.magic_card_id
          FROM Transactions
          WHERE Transactions.buyer_id = #{@user.id} AND status = 'buying'
          GROUP BY Transactions.magic_card_id
        ) GROUP BY Magic_Sets.code, Magic_Sets.name"
      @collection_sets = ActiveRecord::Base.connection.execute(collection_sets_sql)
    end
    respond_to do |format|
      format.html
      format.json { render json: json }
    end
  end

  def transactions
  end

  def transfers
    @magic_accounts = @user.magic_accounts.order(:created_at)
  end

  def get_transfer_data
    errors = false
    errors = true unless account_valid?
    errors = true unless associated_account?
    redirect_to user_transfer_error_path(@user) and return if errors == true
    @account = MagicAccount.where(user_id: @user.id, name: params[:magic_account]).first
    @depositing = Stock.find_by_sql(["SELECT Stocks.magic_card_id, Magic_Cards.name, Magic_Cards.mtgo_id, Magic_Cards.foil, Magic_Sets.code, COUNT (*) AS quantity
      FROM Stocks JOIN Magic_Cards ON Stocks.magic_card_id = Magic_Cards.id JOIN Magic_Sets ON Magic_Cards.magic_set_id = Magic_Sets.id
      WHERE Stocks.user_id = ? AND Stocks.magic_account_id = ? AND Stocks.status = 'depositing'
      GROUP BY Stocks.magic_card_id, Magic_Cards.name, Magic_Cards.mtgo_id, Magic_Cards.foil, Magic_Sets.code
      ORDER BY Magic_Cards.name
      ", "#{@user.id}", "#{@account.id}"])
    @withdrawing = Stock.find_by_sql(["SELECT Stocks.magic_card_id, Magic_Cards.name, Magic_Cards.mtgo_id, Magic_Cards.foil, Magic_Sets.code, COUNT (*) AS quantity
      FROM Stocks JOIN Magic_Cards ON Stocks.magic_card_id = Magic_Cards.id JOIN Magic_Sets ON Magic_Cards.magic_set_id = Magic_Sets.id
      WHERE Stocks.user_id = ? AND Stocks.magic_account_id = ? AND Stocks.status = 'withdrawing'
      GROUP BY Stocks.magic_card_id, Magic_Cards.name, Magic_Cards.mtgo_id, Magic_Cards.foil, Magic_Sets.code
      ORDER BY Magic_Cards.name
      ", "#{@user.id}", "#{@account.id}"])
    render partial: 'users/transfer_data'
  end

  def post_transfer_data
    errors = false
    errors = true unless account_valid?
    errors = true unless associated_account?
    @set = MagicSet.find_by_name( params[:set] )
    if @set != nil
      if params[:foil] == "foil"
        @card = MagicCard.where(name: params[:card], magic_set_id: @set.id, foil: true)
      else 
        @card = MagicCard.where(name: params[:card], magic_set_id: @set.id, foil: false)
      end       
    else
      @card = []
      errors = true
    end
    errors = true unless @card.count == 1
    errors = true unless ["deposit", "withdraw"].include?(params[:direction])
    redirect_to user_transfer_error_path(@user) and return if errors == true
    @account = MagicAccount.where(user_id: @user.id, name: params[:magic_account]).first
    @card = @card.first
    case params[:direction]
      when "deposit"
        errors = true if @account.tickets_depositing + Stock.where(user_id: @user.id, magic_account_id: @account.id, status: "depositing").count >= 400
        errors = true if Stock.where(user_id: @user.id, magic_account_id: @account.id, status: "depositing", magic_card_id: @card.id).count != 0
      when "withdraw"
        errors = true if @account.tickets_withdrawing + Stock.where(user_id: @user.id, magic_account_id: @account.id, status: "withdrawing").count >= 400
        errors = true if Stock.where(user_id: @user.id, magic_account_id: @account.id, status: "withdrawing", magic_card_id: @card.id).count != 0
        errors = true if Stock.where(user_id: @user.id, status: "online", magic_card_id: @card.id).count < 1 
      else
        errors = true
    end
    redirect_to user_transfer_error_path(@user) and return if errors == true
    case params[:direction]
      when "deposit"
        Stock.create(user_id: @user.id, magic_account_id: @account.id, status: "depositing", magic_card_id: @card.id)
      when "withdraw"
        Stock.where(user_id: @user.id, status: "online", magic_card_id: @card.id).first.update_attributes(status: "withdrawing", magic_account_id: @account.id)
    end
    @depositing = Stock.find_by_sql(["SELECT Stocks.magic_card_id, Magic_Cards.name, Magic_Cards.mtgo_id, Magic_Cards.foil, Magic_Sets.code, COUNT (*) AS quantity
      FROM Stocks JOIN Magic_Cards ON Stocks.magic_card_id = Magic_Cards.id JOIN Magic_Sets ON Magic_Cards.magic_set_id = Magic_Sets.id
      WHERE Stocks.user_id = ? AND Stocks.magic_account_id = ? AND Stocks.status = 'depositing'
      GROUP BY Stocks.magic_card_id, Magic_Cards.name, Magic_Cards.mtgo_id, Magic_Cards.foil, Magic_Sets.code
      ORDER BY Magic_Cards.name
      ", "#{@user.id}", "#{@account.id}"])
    @withdrawing = Stock.find_by_sql(["SELECT Stocks.magic_card_id, Magic_Cards.name, Magic_Cards.mtgo_id, Magic_Cards.foil, Magic_Sets.code, COUNT (*) AS quantity
      FROM Stocks JOIN Magic_Cards ON Stocks.magic_card_id = Magic_Cards.id JOIN Magic_Sets ON Magic_Cards.magic_set_id = Magic_Sets.id
      WHERE Stocks.user_id = ? AND Stocks.magic_account_id = ? AND Stocks.status = 'withdrawing'
      GROUP BY Stocks.magic_card_id, Magic_Cards.name, Magic_Cards.mtgo_id, Magic_Cards.foil, Magic_Sets.code
      ORDER BY Magic_Cards.name
      ", "#{@user.id}", "#{@account.id}"])
    render partial: 'users/transfer_data'
  end

  def transfer_check_card
    errors = false
    errors = true unless account_valid?
    errors = true unless associated_account?
    @set = MagicSet.find_by_name( params[:set] )
    @set ||= MagicSet.find_by_code( params[:set] )
    if @set != nil
      if params[:foil] == "foil" || params[:foil] == "F" 
        @card = MagicCard.where(name: params[:card], magic_set_id: @set.id, foil: true)
      else 
        @card = MagicCard.where(name: params[:card], magic_set_id: @set.id, foil: false)
      end       
    else
      @card = []
      errors = true
    end
    errors = true unless @card.count == 1
    redirect_to user_transfer_error_path(@user) and return if errors == true
    @account = MagicAccount.where(user_id: @user.id, name: params[:magic_account]).first
    @card = @card.first
    @transfering = "no"
    @transfering = "yes" if Stock.where(user_id: @user.id, magic_account_id: @account.id, status: "depositing", magic_card_id: @card.id).count != 0
    @transfering = "yes" if Stock.where(user_id: @user.id, magic_account_id: @account.id, status: "withdrawing", magic_card_id: @card.id).count != 0
    @online = "no"
    @online = "yes" if Stock.where(user_id: @user.id, status: "online", magic_card_id: @card.id).count > 0 
    @online_count = Stock.where(user_id: @user.id, status: "online", magic_card_id: @card.id).count
    render partial: 'users/transfer_check_card'
  end

  def transfer_error
    render partial: 'users/transfer_error'
  end

  def transfer_edit
    errors = false
    errors = true unless account_valid?
    errors = true unless associated_account?
    if params[:card] == "Tickets"
      errors = true unless ["edit_ok", "edit_deposit", "edit_withdraw", "edit_remove"].include?(params[:edit_type])
      quantity = params[:quantity].to_i
      errors = true unless (( quantity >= 1 && quantity <= 400 ) || params[:edit_type] == "edit_remove") 
      redirect_to user_transfer_error_path(@user) and return if errors == true
      @account = MagicAccount.where(user_id: @user.id, name: params[:magic_account]).first
      depositing_count = @account.tickets_depositing
      withdrawing_count = @account.tickets_withdrawing
      online_count = @user.wallet
      errors = true if ( depositing_count > 0 && withdrawing_count > 0) 
      redirect_to user_transfer_error_path(@user) and return if errors == true
      depositing_total = @account.tickets_depositing + Stock.where(user_id: @user.id, magic_account_id: @account.id, status: "depositing").count
      withdrawing_total = @account.tickets_withdrawing + Stock.where(user_id: @user.id, magic_account_id: @account.id, status: "withdrawing").count
      if depositing_count > 0 
        direction = "depositing"
      elsif withdrawing_count > 0
        direction = "withdrawing"
      else 
        direction = ""
      end
      case params[:edit_type]
        when "edit_ok"
          if direction == "depositing"
            errors = true if depositing_total - depositing_count + quantity > 400
          else
            errors = true if withdrawing_total - withdrawing_count + quantity > 400
            errors = true if withdrawing_count + online_count < quantity
          end
        when "edit_deposit"
          errors = true if direction == "depositing"
          errors = true if depositing_total + quantity > 400
        when "edit_withdraw"
          errors = true if direction == "withdrawing"
          errors = true if withdrawing_total + quantity > 400
          errors = true if online_count < quantity
        when "edit_remove"
        else
          errors = true
      end
      redirect_to user_transfer_error_path(@user) and return if errors == true
      case params[:edit_type]
        when "edit_ok"
          if direction == "depositing"
            @account.update_attribute(:tickets_depositing, quantity)
          else
            @user.update_attribute(:wallet, (online_count - quantity + withdrawing_count ) )
            @account.update_attribute(:tickets_withdrawing, quantity)
          end
        when "edit_deposit"
          @account.update_attribute(:tickets_depositing, quantity)
          @user.update_attribute(:wallet, (online_count + withdrawing_count ) )
          @account.update_attribute(:tickets_withdrawing, 0)
        when "edit_withdraw"
          @account.update_attribute(:tickets_depositing, 0)
          @user.update_attribute(:wallet, (online_count - quantity ) )
          @account.update_attribute(:tickets_withdrawing, quantity)
        when "edit_remove"
          if direction == "depositing"
            @account.update_attribute(:tickets_depositing, 0)
          else
            @user.update_attribute(:wallet, (online_count + withdrawing_count ) )
            @account.update_attribute(:tickets_withdrawing, 0)
          end
      end
    else
      @set = MagicSet.find_by_code( params[:set] )
      @card = []
      if @set != nil
        if params[:foil] == "foil"
          @card = MagicCard.where(name: params[:card], magic_set_id: @set.id, foil: true)
        else 
          @card = MagicCard.where(name: params[:card], magic_set_id: @set.id, foil: false)
        end       
      else
        errors = true
      end
      errors = true unless @card.count == 1
      errors = true unless ["edit_ok", "edit_deposit", "edit_withdraw", "edit_remove"].include?(params[:edit_type])
      quantity = params[:quantity].to_i
      errors = true unless (( quantity >= 1 && quantity <= 400 ) || params[:edit_type] == "edit_remove") 
      redirect_to user_transfer_error_path(@user) and return if errors == true
      @account = MagicAccount.where(user_id: @user.id, name: params[:magic_account]).first
      @card = @card.first
      depositing_count = Stock.where(user_id: @user.id, magic_account_id: @account.id, status: "depositing", magic_card_id: @card.id).count
      withdrawing_count = Stock.where(user_id: @user.id, magic_account_id: @account.id, status: "withdrawing", magic_card_id: @card.id).count
      errors = true if ((depositing_count > 0 && withdrawing_count > 0) || ( depositing_count == 0 && withdrawing_count == 0))
      redirect_to user_transfer_error_path(@user) and return if errors == true
      if depositing_count > 0 
        direction = "depositing"
      else
        direction = "withdrawing"
      end
      online_count = Stock.where(user_id: @user.id, status: "online", magic_card_id: @card.id).count
      depositing_total = @account.tickets_depositing + Stock.where(user_id: @user.id, magic_account_id: @account.id, status: "depositing").count
      withdrawing_total = @account.tickets_withdrawing + Stock.where(user_id: @user.id, magic_account_id: @account.id, status: "withdrawing").count
      case params[:edit_type]
        when "edit_ok"
          if direction == "depositing"
            errors = true if depositing_total - depositing_count + quantity > 400
          else
            errors = true if withdrawing_total - withdrawing_count + quantity > 400
            errors = true if withdrawing_count + online_count < quantity
          end
        when "edit_deposit"
          errors = true if direction == "depositing"
          errors = true if depositing_total + quantity > 400
        when "edit_withdraw"
          errors = true if direction == "withdrawing"
          errors = true if withdrawing_total + quantity > 400
          errors = true if online_count < quantity
        when "edit_remove"
        else
          errors = true
      end
      redirect_to user_transfer_error_path(@user) and return if errors == true
      case params[:edit_type]
        when "edit_ok"
          if direction == "depositing"
            if quantity > depositing_count
              (quantity-depositing_count).times do 
                Stock.create(user_id: @user.id, magic_account_id: @account.id, status: "depositing", magic_card_id: @card.id)
              end
            elsif quantity < depositing_count
              (depositing_count-quantity).times do 
                Stock.where(user_id: @user.id, magic_account_id: @account.id, status: "depositing", magic_card_id: @card.id).first.destroy
              end
            end
          else
            if quantity > withdrawing_count
              (quantity-withdrawing_count).times do 
                Stock.where(user_id: @user.id, status: "online", magic_card_id: @card.id).first.update_attributes(status: "withdrawing", magic_account_id: @account.id)
              end
            elsif quantity < withdrawing_count
              (withdrawing_count-quantity).times do 
                Stock.where(user_id: @user.id, magic_account_id: @account.id, status: "withdrawing", magic_card_id: @card.id).first.update_attributes(status: "online", magic_account_id: "")
              end
            end
          end
        when "edit_deposit"
          (withdrawing_count).times do 
            Stock.where(user_id: @user.id, magic_account_id: @account.id, status: "withdrawing", magic_card_id: @card.id).first.update_attributes(status: "online", magic_account_id: "")
          end
          (quantity).times do 
            Stock.create(user_id: @user.id, magic_account_id: @account.id, status: "depositing", magic_card_id: @card.id)
          end
        when "edit_withdraw"
          Stock.where(user_id: @user.id, magic_account_id: @account.id, status: "depositing", magic_card_id: @card.id).destroy_all
          (quantity).times do 
            Stock.where(user_id: @user.id, status: "online", magic_card_id: @card.id).first.update_attributes(status: "withdrawing", magic_account_id: @account.id)
          end
        when "edit_remove"
          if direction == "depositing"
            Stock.where(user_id: @user.id, magic_account_id: @account.id, status: "depositing", magic_card_id: @card.id).destroy_all
          else
            Stock.where(user_id: @user.id, magic_account_id: @account.id, status: "withdrawing", magic_card_id: @card.id).update_all(status: "online", magic_account_id: "")
          end
      end
    end
    @depositing = Stock.find_by_sql(["SELECT Stocks.magic_card_id, Magic_Cards.name, Magic_Cards.mtgo_id, Magic_Cards.foil, Magic_Sets.code, COUNT (*) AS quantity
      FROM Stocks JOIN Magic_Cards ON Stocks.magic_card_id = Magic_Cards.id JOIN Magic_Sets ON Magic_Cards.magic_set_id = Magic_Sets.id
      WHERE Stocks.user_id = ? AND Stocks.magic_account_id = ? AND Stocks.status = 'depositing'
      GROUP BY Stocks.magic_card_id, Magic_Cards.name, Magic_Cards.mtgo_id, Magic_Cards.foil, Magic_Sets.code
      ORDER BY Magic_Cards.name
      ", "#{@user.id}", "#{@account.id}"])
    @withdrawing = Stock.find_by_sql(["SELECT Stocks.magic_card_id, Magic_Cards.name, Magic_Cards.mtgo_id, Magic_Cards.foil, Magic_Sets.code, COUNT (*) AS quantity
      FROM Stocks JOIN Magic_Cards ON Stocks.magic_card_id = Magic_Cards.id JOIN Magic_Sets ON Magic_Cards.magic_set_id = Magic_Sets.id
      WHERE Stocks.user_id = ? AND Stocks.magic_account_id = ? AND Stocks.status = 'withdrawing'
      GROUP BY Stocks.magic_card_id, Magic_Cards.name, Magic_Cards.mtgo_id, Magic_Cards.foil, Magic_Sets.code
      ORDER BY Magic_Cards.name
      ", "#{@user.id}", "#{@account.id}"])
    render partial: 'users/transfer_data'
  end

  def transfer_clear_account
    errors = false
    errors = true unless account_valid?
    errors = true unless associated_account?
    redirect_to user_transfer_error_path(@user) and return if errors == true
    @account = MagicAccount.where(user_id: @user.id, name: params[:magic_account]).first
    Stock.where(user_id: @user.id, magic_account_id: @account.id, status: "depositing").destroy_all
    Stock.where(user_id: @user.id, magic_account_id: @account.id, status: "withdrawing").update_all(status: "online", magic_account_id: "")
    @account.update_attribute(:tickets_depositing, 0)
    new_wallet = @user.wallet + @account.tickets_withdrawing
    @user.update_attribute(:wallet, new_wallet)
    @account.update_attribute(:tickets_withdrawing, 0)
    @depositing = []
    @withdrawing = []
    render partial: 'users/transfer_data'
  end

  def change_password
  end

  def mtgo_accounts
    @magic_accounts = @user.magic_accounts.order(:created_at)
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
