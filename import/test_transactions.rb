@buyer_id = User.all.first.id
@seller_id = User.all.last.id
@stock_id = Stock.where(status: "online").first.id

MagicCard.all.each do |card|
  @card_id = card.id
  @stock_id ||= Stock.where(status: "online", magic_card_id: @card_id).first.id
  @price_range = [0,1,2].sample
  rand(50...500).times do
    @transaction = Transaction.create(buyer_id: @buyer_id, seller_id: @seller_id, magic_card_id: @card_id, start: 1.month.ago, finish: rand(1.year.ago..Time.now), status: "finished", price: [rand(0.010..2.000), rand(2.00..10.00), rand(10.0..35.00)][@price_range], stock_id: @stock_id)
  end
end
