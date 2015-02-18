class MagicCardsController < ApplicationController
  def show
  	@set = MagicSet.find_by(code: params[:magic_set_id].upcase)
  	redirect_to '/' and return if @set.nil?
  	@object = MagicCard.find_by(mtgo_id: params[:id])
  	redirect_to magic_set_path(@set) and return if @object.nil?
    redirect_to magic_set_path(@set) and return if @object.disabled

    versions_sql = "SELECT 
      Magic_Cards.id, Magic_Cards.mtgo_id, Magic_Cards.name, Magic_Cards.plain_name, Magic_Cards.foil, Magic_Cards.rarity, Magic_Cards.object_type, Magic_Cards.magic_set_id 
      , (SELECT MAX(Transactions.price) FROM Transactions WHERE (Transactions.magic_card_id = Magic_Cards.id AND Transactions.status = 'buying')) AS buying_price 
      , (SELECT MIN(Transactions.price) FROM Transactions WHERE (Transactions.magic_card_id = Magic_Cards.id AND Transactions.status = 'selling')) AS selling_price" 
    versions_sql += "
      , (SELECT COUNT(*) FROM Stocks WHERE (Stocks.magic_card_id = Magic_Cards.id AND Stocks.status = 'online' AND Stocks.user_id = #{@user.id})) AS online
      , (SELECT COUNT(*) FROM Stocks WHERE (Stocks.magic_card_id = Magic_Cards.id AND Stocks.status = 'depositing' AND Stocks.user_id = #{@user.id})) AS depositing
      , (SELECT COUNT(*) FROM Stocks WHERE (Stocks.magic_card_id = Magic_Cards.id AND Stocks.status = 'withdrawing' AND Stocks.user_id = #{@user.id})) AS withdrawing
      , (SELECT COUNT(*) FROM Stocks WHERE (Stocks.magic_card_id = Magic_Cards.id AND Stocks.status = 'offline' AND Stocks.user_id = #{@user.id})) AS offline 
      , (SELECT COUNT(*) FROM Stocks WHERE (Stocks.magic_card_id = Magic_Cards.id AND Stocks.status = 'selling' AND Stocks.user_id = #{@user.id})) AS selling
      , (SELECT COUNT(*) FROM Transactions WHERE (Transactions.magic_card_id = Magic_Cards.id AND Transactions.status = 'buying' AND Transactions.buyer_id = #{@user.id})) AS buying
      " if @user.present?
    versions_sql += " FROM Magic_Cards WHERE (Magic_Cards.disabled = false AND 
      Magic_Cards.name = $$"+@object.name.chomp(" (Alt.)")+"$$ OR
      Magic_Cards.name = $$"+@object.name+" (Alt.)$$ OR
      Magic_Cards.name = $$"+@object.name+"$$
      ) ORDER BY Magic_Cards.id ASC"
    @versions = MagicCard.find_by_sql(versions_sql)

    @bids = Transaction.find_by_sql("SELECT t.price, t.magic_card_id, t.status,
      (SELECT COUNT(*) FROM Transactions WHERE Transactions.magic_card_id = #{@object.id} AND Transactions.price = t.price AND Transactions.status = 'buying') AS num_bids
      FROM Transactions AS t WHERE t.magic_card_id = #{@object.id} AND t.status = 'buying' GROUP BY t.price, t.magic_card_id, t.status ORDER BY t.price DESC").first(10)
    @listings = Transaction.find_by_sql("SELECT t.price, t.magic_card_id, t.status,
      (SELECT COUNT(*) FROM Transactions WHERE Transactions.magic_card_id = #{@object.id} AND Transactions.price = t.price AND Transactions.status = 'selling') AS num_listings
      FROM Transactions AS t WHERE t.magic_card_id = #{@object.id} AND t.status = 'selling' GROUP BY t.price, t.magic_card_id, t.status ORDER BY t.price ASC").first(10)
    @sales = Transaction.find_by_sql("SELECT t.price, t.magic_card_id, t.status, date_trunc('second', t.finish) AS truncated_finish,
      (SELECT COUNT(*) FROM Transactions WHERE Transactions.magic_card_id = #{@object.id} AND Transactions.price = t.price AND Transactions.status = 'finished') AS num_sales
      FROM Transactions AS t WHERE t.magic_card_id = #{@object.id} AND t.status = 'finished' GROUP BY t.price, t.magic_card_id, t.status, truncated_finish ORDER BY truncated_finish DESC").first(10)

    if @user.present?
      @user_bids = Transaction.find_by_sql("SELECT t.price, t.magic_card_id, t.status,
        (SELECT COUNT(*) FROM Transactions WHERE Transactions.magic_card_id = #{@object.id} AND Transactions.price = t.price AND Transactions.status = 'buying') AS num_bids
        FROM Transactions AS t WHERE t.magic_card_id = #{@object.id} AND t.status = 'buying' AND t.buyer_id = #{@user.id} GROUP BY t.price, t.magic_card_id, t.status ORDER BY t.price DESC")
      @user_listings = Transaction.find_by_sql("SELECT t.price, t.magic_card_id, t.status,
        (SELECT COUNT(*) FROM Transactions WHERE Transactions.magic_card_id = #{@object.id} AND Transactions.price = t.price AND Transactions.status = 'selling') AS num_listings
        FROM Transactions AS t WHERE t.magic_card_id = #{@object.id} AND t.status = 'selling' AND t.seller_id = #{@user.id} GROUP BY t.price, t.magic_card_id, t.status ORDER BY t.price ASC")
    end


  end
end
