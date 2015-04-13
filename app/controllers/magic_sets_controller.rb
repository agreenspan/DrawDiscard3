class MagicSetsController < ApplicationController
  def show
    @set = MagicSet.find_by(code: params[:id].upcase)
    redirect_to '/' and return if @set.nil?
    @disabled = @set.magic_cards.where(disabled: true)
    if @disabled.present?
      @disabled_cards = @disabled.where(object_type: 'card').present? 
      @disabled_packs = @disabled.where(object_type: 'pack').present?
      #@disabled_vanguards = @disabled.where(object_type: 'planar').present?
      #@disabled_planars = @disabled.where(object_type: 'vanguard').present?
    end

    objects_sql = "SELECT 
      Magic_Cards.id, Magic_Cards.mtgo_id, Magic_Cards.name, Magic_Cards.plain_name, Magic_Cards.foil, Magic_Cards.rarity, Magic_Cards.object_type, Magic_Cards.magic_set_id 
      , (SELECT MAX(Transactions.price) FROM Transactions WHERE (Transactions.magic_card_id = Magic_Cards.id AND Transactions.status = 'buying')) AS buying_price 
      , (SELECT MIN(Transactions.price) FROM Transactions WHERE (Transactions.magic_card_id = Magic_Cards.id AND Transactions.status = 'selling')) AS selling_price" 
    objects_sql += "
      , (SELECT COUNT(*) FROM Stocks WHERE (Stocks.magic_card_id = Magic_Cards.id AND Stocks.status = 'online' AND Stocks.user_id = #{@user.id})) AS online
      , (SELECT COUNT(*) FROM Stocks WHERE (Stocks.magic_card_id = Magic_Cards.id AND Stocks.status = 'depositing' AND Stocks.user_id = #{@user.id})) AS depositing
      , (SELECT COUNT(*) FROM Stocks WHERE (Stocks.magic_card_id = Magic_Cards.id AND Stocks.status = 'withdrawing' AND Stocks.user_id = #{@user.id})) AS withdrawing
      , (SELECT COUNT(*) FROM Stocks WHERE (Stocks.magic_card_id = Magic_Cards.id AND Stocks.status = 'selling' AND Stocks.user_id = #{@user.id})) AS selling
      , (SELECT COUNT(*) FROM Transactions WHERE (Transactions.magic_card_id = Magic_Cards.id AND Transactions.status = 'buying' AND Transactions.buyer_id = #{@user.id})) AS buying
      " if @user.present?
    objects_sql += " FROM Magic_Cards WHERE (disabled = false AND magic_set_id = #{@set.id}) ORDER BY Magic_Cards.id ASC"
    @objects = MagicCard.find_by_sql(objects_sql)

    @cards = [] 
    @packs = [] 
    @planars = [] 
    @vanguards = [] 
    configure_filters(false, false, true)

  end

  def packs
    objects_sql = "SELECT 
      Magic_Cards.id, Magic_Cards.mtgo_id, Magic_Cards.name, Magic_Cards.object_type, Magic_Cards.magic_set_id, (Magic_Sets.name) AS set_name, Magic_Sets.code, 
      (SELECT MAX(Transactions.price) FROM Transactions WHERE (Transactions.magic_card_id = Magic_Cards.id AND Transactions.status = 'buying')) AS buying_price, 
      (SELECT MIN(Transactions.price) FROM Transactions WHERE (Transactions.magic_card_id = Magic_Cards.id AND Transactions.status = 'selling')) AS selling_price" 
    objects_sql += "
      , (SELECT COUNT(*) FROM Stocks WHERE (Stocks.magic_card_id = Magic_Cards.id AND Stocks.status = 'online' AND Stocks.user_id = #{@user.id})) AS online
      , (SELECT COUNT(*) FROM Stocks WHERE (Stocks.magic_card_id = Magic_Cards.id AND Stocks.status = 'depositing' AND Stocks.user_id = #{@user.id})) AS depositing
      , (SELECT COUNT(*) FROM Stocks WHERE (Stocks.magic_card_id = Magic_Cards.id AND Stocks.status = 'withdrawing' AND Stocks.user_id = #{@user.id})) AS withdrawing
      , (SELECT COUNT(*) FROM Stocks WHERE (Stocks.magic_card_id = Magic_Cards.id AND Stocks.status = 'selling' AND Stocks.user_id = #{@user.id})) AS selling
      , (SELECT COUNT(*) FROM Transactions WHERE (Transactions.magic_card_id = Magic_Cards.id AND Transactions.status = 'buying' AND Transactions.buyer_id = #{@user.id})) AS buying
      " if @user.present?
    objects_sql += " FROM Magic_Cards JOIN Magic_sets ON Magic_Cards.magic_set_id = Magic_Sets.id WHERE (disabled = false AND object_type = 'pack') ORDER BY Magic_Cards.id ASC"
    @objects = MagicCard.find_by_sql(objects_sql)

    @packs = []
    configure_filters(true, false, false)

  end

  def planars
    objects_sql = "SELECT 
      Magic_Cards.id, Magic_Cards.mtgo_id, Magic_Cards.name, Magic_Cards.plain_name, Magic_Cards.foil, Magic_Cards.object_type, Magic_Cards.magic_set_id, (Magic_Sets.name) AS set_name, Magic_Sets.code, 
      (SELECT MAX(Transactions.price) FROM Transactions WHERE (Transactions.magic_card_id = Magic_Cards.id AND Transactions.status = 'buying')) AS buying_price, 
      (SELECT MIN(Transactions.price) FROM Transactions WHERE (Transactions.magic_card_id = Magic_Cards.id AND Transactions.status = 'selling')) AS selling_price" 
    objects_sql += "
      , (SELECT COUNT(*) FROM Stocks WHERE (Stocks.magic_card_id = Magic_Cards.id AND Stocks.status = 'online' AND Stocks.user_id = #{@user.id})) AS online
      , (SELECT COUNT(*) FROM Stocks WHERE (Stocks.magic_card_id = Magic_Cards.id AND Stocks.status = 'depositing' AND Stocks.user_id = #{@user.id})) AS depositing
      , (SELECT COUNT(*) FROM Stocks WHERE (Stocks.magic_card_id = Magic_Cards.id AND Stocks.status = 'withdrawing' AND Stocks.user_id = #{@user.id})) AS withdrawing
      , (SELECT COUNT(*) FROM Stocks WHERE (Stocks.magic_card_id = Magic_Cards.id AND Stocks.status = 'selling' AND Stocks.user_id = #{@user.id})) AS selling
      , (SELECT COUNT(*) FROM Transactions WHERE (Transactions.magic_card_id = Magic_Cards.id AND Transactions.status = 'buying' AND Transactions.buyer_id = #{@user.id})) AS buying
      " if @user.present?
    objects_sql += " FROM Magic_Cards JOIN Magic_sets ON Magic_Cards.magic_set_id = Magic_Sets.id WHERE (disabled = false AND object_type = 'planar') ORDER BY Magic_Cards.id ASC"
    @objects = MagicCard.find_by_sql(objects_sql)

    @planars = []
    configure_filters(false, true, false)

  end

end
