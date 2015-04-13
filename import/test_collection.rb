def make_samples(object, object_id)

  rand(0...12).times do
    Stock.create(user_id: @user.id, status: "offline", magic_account_id: @account.id, object_id => object.id)
  end
  @price = nil
  @price = Transaction.where(status: "selling", object_id => object.id).order(price: :asc).first.price if Transaction.where(status: "selling", object_id => object.id).present?
  @price ||= Transaction.where(status: "buying", object_id => object.id).order(price: :desc).first.price if Transaction.where(status: "buying", object_id => object.id).present?
  @price ||= [ ((1.8 * rand()).round(3)+0.020) , (8 * rand() + 2).round(2) , (20 * rand() + 10).round(1) ].sample
  rand(0...6).times do
    if @price < 2
      @selling_price = (@price + (9 * rand() + 1)/1000)
      @selling_price = @selling_price.round(3) if @selling_price <= 2
      @selling_price = @selling_price.round(2) if @selling_price >= 2
    elsif @price >= 2 && @price < 10
      @selling_price = (@price + (14 * rand() + 1)/100) 
      @selling_price = @selling_price.round(3) if @selling_price <= 2
      @selling_price = @selling_price.round(2) if (@selling_price >= 2 && @selling_price <= 10) 
      @selling_price = @selling_price.round(1) if @selling_price >= 10
    else
      @selling_price = (@price + (19 * rand() + 1)/10)
      @selling_price = @selling_price.round(2) if @selling_price <= 10
      @selling_price = @selling_price.round(1) if @selling_price >= 10
    end
    @selling = Stock.create(user_id: @user.id, status: "selling", bot_id: @bank.id, object_id => object.id)
    @transaction = Transaction.create(seller_id: @user.id, object_id => object.id, stock_id: @selling.id, start: Time.now, status: "selling", price: @selling_price)
  end
  rand(0...6).times do
    if @price < 2
      @buying_price = (@price - (9 * rand() + 1)/1000)
      @buying_price = @buying_price.round(3) if @buying_price <= 2
      @buying_price = @buying_price.round(2) if @buying_price >= 2
    elsif @price >= 2 && @price < 10
      @buying_price = (@price - (14 * rand() + 1)/100)
      @buying_price = @buying_price.round(3) if @buying_price <= 2
      @buying_price = @buying_price.round(2) if (@buying_price >= 2 && @buying_price <= 10) 
      @buying_price = @buying_price.round(1) if @buying_price >= 10
    else
      @buying_price = (@price - (19 * rand() + 1)/10)
      @buying_price = @buying_price.round(2) if @buying_price <= 10 
      @buying_price = @buying_price.round(1) if @buying_price >= 10
    end
    @transaction = Transaction.create(buyer_id: @user.id, object_id => object.id, start: Time.now, status: "buying", price: @buying_price)
  end

end

@bank = Bot.create(name: "test_bank", role: "bank")
@users = [{email: "greenspan.aron@gmail.com", password: "ewewewew"}, {email: "aronskis@aol.com", password: "ewewewew"}, {email: "test@test.com", password: "testtest"}]
@users.each do |user|
  @user = User.create(email: user[:email], password: user[:password], password_confirmation: user[:password])
  @user.update_attribute(:confirmed, true)
  @user.update_attributes(user_code: "123456", bot_code: "654321", wallet: 1000.0)
  @account = MagicAccount.create(user_id: @user.id, name: "sample")
  MagicCard.all.each do |card|
    make_samples(card, 'magic_card_id')
  end

end



