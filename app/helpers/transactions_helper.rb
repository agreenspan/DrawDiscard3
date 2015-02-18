module TransactionsHelper

  def valid_float?(string)
    !!Float(string) rescue false
  end

  def price_valid?
    if params[:price].empty? || params[:price].blank?
      flash_message :danger, "Price cannot be blank."
      return false
    elsif !valid_float?(params[:price])
      flash_message :danger, "Price must be a number."
      return false
    elsif params[:price].to_f < 0.01
      flash_message :danger, "Price cannot be less than 0.01 tickets."
      return false
    elsif params[:price].to_f > 999.9
      flash_message :danger, "Price cannot be greater than 999.9 tickets."
      return false
    else 
      price = params[:price].to_f
      if (price < 2) && (price != price.round(3))
        flash_message :danger, "Prices under 2 tickets must be set in increments of 0.001."
        return false
      elsif (price < 10) && (price != price.round(2))
        flash_message :danger, "Prices between 2 and 10 tickets must be set in increments of 0.01."
        return false
      elsif (price > 10) && (price != price.round(1))
        flash_message :danger, "Prices above 10 tickets must be set in increments of 0.1."
        return false
      else
        return true
      end
    end
  end

  def quantity_valid?
    if params[:quantity].empty? || params[:quantity].blank?
      flash_message :danger, "Quantity cannot be blank."
      return false
    elsif params[:quantity].to_i.to_s != params[:quantity]
      flash_message :danger, "Quantity must be an integer."
      return false
    elsif params[:quantity].to_i < 1
      flash_message :danger, "Quantity cannot be less than 1."
      return false
    elsif params[:quantity].to_i > 999
      flash_message :danger, "Quantity cannot be greater than 999."
      return false
    else 
      return true
    end
  end

  def object_valid?
    if params[:mtgo_id].empty? || params[:mtgo_id].blank?
      flash_message :danger, "Card ID blank."
      return false
    elsif MagicCard.where(mtgo_id: params[:mtgo_id], disabled: false).count < 1
      flash_message :danger, "Invalid card ID."
      return false
    else 
      return true
    end
  end

  def enough_tickets?
    if params[:price].to_f * params[:quantity].to_i > @user.wallet
      flash_message :danger, "You do not have enough tickets for this purchase."
      return false
    else
      return true
    end
  end

  def enough_cards?
    if params[:quantity].to_i > Stock.where(user_id: @user.id, status: "online", magic_card_id: MagicCard.find_by(mtgo_id: params[:mtgo_id])).count
      flash_message :danger, "You do not have that many copies on DrawDiscard."
      return false
    else
      return true
    end
  end

  def buy
    @price = params[:price].to_f
    @quantity = params[:quantity].to_i
    @object = MagicCard.find_by(mtgo_id: params[:mtgo_id])
    @buyer = @user
    bid_count = 0
    buy_log = Hash.new
    catch :buy_from_self do
      catch :ran_out_of_tickets do
        @quantity.times do
          complete = false
          until complete
            if Transaction.where("magic_card_id = ? AND status = ? AND price <= ?", @object.id, "selling", @price).empty?
              @buyer.with_lock do
                if @buyer.wallet < @price
                  flash_message :warning, "Buying stopped when you had insufficient tickets."
                  throw :ran_out_of_tickets
                else
                  @buyer.update_attribute(:wallet, @buyer.wallet - @price)
                  @transaction = Transaction.create(magic_card_id: @object.id, status: "buying", price: @price, buyer_id: @buyer.id, start: @time)
                  bid_count += 1
                  complete = true
                end
              end
            else 
              @transaction = Transaction.where("magic_card_id = ? AND status = ? AND price <= ? AND seller_id != ?", @object.id, "selling", @price, @buyer.id).order(price: :asc, start: :asc).first
              if @transaction.nil?
                flash_message :info, "Buying stopped at the point where you are the seller."
                throw :buy_from_self
              end
              @transaction.with_lock do
                if @transaction.status == "selling"
                  @stock = Stock.find(@transaction.stock_id)
                  @stock.with_lock do
                    if @stock.status == "selling"
                      @buyer.with_lock do
                        price = @transaction.price
                        if @buyer.wallet < price
                          flash_message :warning, "Buying stopped when you had insufficient tickets."
                          throw :ran_out_of_tickets
                        else
                          @transaction.update_attributes(status: "finished", finish: @time, buyer_id: @buyer.id)
                          @stock.update_attributes(status: "online", user_id: @buyer.id)
                          @buyer.update_attribute(:wallet, @buyer.wallet - price)
                          @seller = User.find(@transaction.seller_id)
                          @seller.with_lock do
                            #FEE GOES HERE
                            @seller.update_attribute(:wallet, @seller.wallet + price)
                          end
                          buy_log[price.to_s.to_sym] ||= 0
                          buy_log[price.to_s.to_sym] += 1
                          complete = true
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
    if bid_count > 0
      flash_message :success, bid_count.to_s+" bid".pluralize(bid_count)+" placed at $#{@price}."
    end
    buy_log.each do |key, value|
      flash_message :success, value.to_s+" copy".pluralize(value)+" bought at $#{key}."
    end
  end

  def sell
    @price = params[:price].to_f
    @quantity = params[:quantity].to_i
    @object = MagicCard.find_by(mtgo_id: params[:mtgo_id])
    @seller = @user  
    list_count = 0
    sell_log = Hash.new
    catch :sell_to_self do
      catch :ran_out_of_copies do
        @quantity.times do
          complete = false
          until complete
            @stock = Stock.where("magic_card_id = ? AND status = ? AND user_id = ?", @object.id, "online", @seller.id).first
            if @stock.nil?
              flash_message :warning, "Selling stopped when you ran out of copies."
              throw :ran_out_of_copies
            end
            if Transaction.where("magic_card_id = ? AND status = ? AND price >= ?", @object.id, "buying", @price).empty?
              @stock.with_lock do
                if @stock.status == "online"
                  @stock.update_attributes(status: "selling")
                  @transaction = Transaction.create(magic_card_id: @object.id, status: "selling", price: @price, seller_id: @seller.id, start: @time, stock_id: @stock.id)
                  list_count += 1
                  complete = true
                end
              end
            else 
              @transaction = Transaction.where("magic_card_id = ? AND status = ? AND price >= ? AND buyer_id != ?", @object.id, "buying", @price, @seller.id).order(price: :desc, start: :asc).first
              if @transaction.nil?
                flash_message :info, "Selling stopped at the point where you are the buyer."
                throw :sell_to_self
              end
              @transaction.with_lock do
                if @transaction.status == "buying"
                  @stock.with_lock do
                    if @stock.status == "online"
                      @buyer = User.find(@transaction.buyer_id)
                      price = @transaction.price
                      @transaction.update_attributes(status: "finished", finish: @time, seller_id: @seller.id, stock_id: @stock.id)
                      @stock.update_attributes(status: "online", user_id: @buyer.id)
                      @seller.with_lock do
                        #FEE GOES HERE
                        @seller.update_attribute(:wallet, @seller.wallet + price)
                      end
                      sell_log[price.to_s.to_sym] ||= 0
                      sell_log[price.to_s.to_sym] += 1
                      complete = true
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
    if list_count > 0
      flash_message :success, list_count.to_s+" listing".pluralize(list_count)+" placed at $#{@price}."
    end
    sell_log.each do |key, value|
      flash_message :success, value.to_s+" copy".pluralize(value)+" sold at $#{key}."
    end
  end

end

