class SearchController < ApplicationController
  def search
    if params[:search].empty?
      flash_message :danger, "Search empty."
      redirect_to :back and return
    end
    if params[:search].length < 3
      flash_message :danger, "Search query too short."
      redirect_to :back and return
    end
    @sets = MagicSet.where('name ILIKE ? OR code ILIKE ?', "%#{params[:search]}%", "%#{params[:search]}%")
    objects_sql = "SELECT 
      Magic_Cards.id, Magic_Cards.mtgo_id, Magic_Cards.name, Magic_Cards.plain_name, Magic_Cards.foil, Magic_Cards.rarity, Magic_Cards.object_type, Magic_Cards.magic_set_id, (Magic_Sets.name) AS set_name, Magic_Sets.code, 
      (SELECT MAX(Transactions.price) FROM Transactions WHERE (Transactions.magic_card_id = Magic_Cards.id AND Transactions.status = 'buying')) AS buying_price, 
      (SELECT MIN(Transactions.price) FROM Transactions WHERE (Transactions.magic_card_id = Magic_Cards.id AND Transactions.status = 'selling')) AS selling_price" 
    objects_sql += "
      , (SELECT COUNT(*) FROM Stocks WHERE (Stocks.magic_card_id = Magic_Cards.id AND Stocks.status = 'online' AND Stocks.user_id = #{@user.id})) AS online
      , (SELECT COUNT(*) FROM Stocks WHERE (Stocks.magic_card_id = Magic_Cards.id AND Stocks.status = 'depositing' AND Stocks.user_id = #{@user.id})) AS depositing
      , (SELECT COUNT(*) FROM Stocks WHERE (Stocks.magic_card_id = Magic_Cards.id AND Stocks.status = 'withdrawing' AND Stocks.user_id = #{@user.id})) AS withdrawing
      , (SELECT COUNT(*) FROM Stocks WHERE (Stocks.magic_card_id = Magic_Cards.id AND Stocks.status = 'offline' AND Stocks.user_id = #{@user.id})) AS offline 
      , (SELECT COUNT(*) FROM Stocks WHERE (Stocks.magic_card_id = Magic_Cards.id AND Stocks.status = 'selling' AND Stocks.user_id = #{@user.id})) AS selling
      , (SELECT COUNT(*) FROM Transactions WHERE (Transactions.magic_card_id = Magic_Cards.id AND Transactions.status = 'buying' AND Transactions.buyer_id = #{@user.id})) AS buying
      " if @user.present?
    objects_sql += " FROM Magic_Cards JOIN Magic_sets ON Magic_Cards.magic_set_id = Magic_Sets.id WHERE (Magic_Cards.name ILIKE ? OR Magic_Cards.plain_name ILIKE ? AND disabled = false) ORDER BY Magic_Cards.id ASC"
    @objects = MagicCard.find_by_sql([objects_sql, "%#{params[:search]}%", "%#{params[:search]}%"])

    @cards = [] 
    @packs = [] 
    @planars = [] 
    @vanguards = [] 
    configure_filters(true, true, false)

  end

end


