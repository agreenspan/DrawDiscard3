class MagicCardsController < ApplicationController
  def show
  	@set = MagicSet.find_by(code: params[:magic_set_id].upcase)
  	redirect_to '/' and return if @set.nil?
  	@object = MagicCard.find_by(mtgo_id: params[:id])
  	redirect_to magic_set_path(@set) and return if @object.nil?
    redirect_to magic_set_path(@set) and return if @object.disabled

    case @object.object_type
      when 'card'
        @other_versions = MagicCard.where(name: @object.name)
      when 'pack'
      when 'planar'
        @other_versions = MagicCard.where(name: @object.name)
      when 'vanguard'
        @other_versions = MagicCard.where(name: @object.name.chomp(" (Alt.)"))
    end
    @other_versions ||=[]


    @bids = Transaction.find_by_sql("SELECT t.price, t.magic_card_id, t.status,
      (SELECT COUNT(*) FROM Transactions WHERE Transactions.magic_card_id = #{@object.id} AND Transactions.price = t.price AND Transactions.status = 'buying') AS num_bids
      FROM Transactions AS t WHERE t.magic_card_id = #{@object.id} AND t.status = 'buying' GROUP BY t.price, t.magic_card_id, t.status ORDER BY t.price DESC").first(10)
    @listings = Transaction.find_by_sql("SELECT t.price, t.magic_card_id, t.status,
      (SELECT COUNT(*) FROM Transactions WHERE Transactions.magic_card_id = #{@object.id} AND Transactions.price = t.price AND Transactions.status = 'selling') AS num_listings
      FROM Transactions AS t WHERE t.magic_card_id = #{@object.id} AND t.status = 'selling' GROUP BY t.price, t.magic_card_id, t.status ORDER BY t.price ASC").first(10)
    @sales = Transaction.find_by_sql("SELECT t.price, t.magic_card_id, t.status, t.finish,
      (SELECT COUNT(*) FROM Transactions WHERE Transactions.magic_card_id = #{@object.id} AND Transactions.price = t.price AND Transactions.status = 'finished') AS num_sales
      FROM Transactions AS t WHERE t.magic_card_id = #{@object.id} AND t.status = 'finished' GROUP BY t.price, t.magic_card_id, t.status, t.finish ORDER BY t.finish DESC").first(10)
















  end
end
