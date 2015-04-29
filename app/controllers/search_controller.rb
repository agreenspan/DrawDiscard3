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
    @sets = MagicSet.where('name ILIKE ? OR code ILIKE ?', "%#{searchable(params[:search])}%", "%#{searchable(params[:search])}%")
    objects_sql = "SELECT 
      Magic_Cards.id, Magic_Cards.mtgo_id, Magic_Cards.name, Magic_Cards.plain_name, Magic_Cards.foil, Magic_Cards.rarity, Magic_Cards.object_type, Magic_Cards.magic_set_id, (Magic_Sets.name) AS set_name, Magic_Sets.code, 
      (SELECT MAX(Transactions.price) FROM Transactions WHERE (Transactions.magic_card_id = Magic_Cards.id AND Transactions.status = 'buying')) AS buying_price, 
      (SELECT MIN(Transactions.price) FROM Transactions WHERE (Transactions.magic_card_id = Magic_Cards.id AND Transactions.status = 'selling')) AS selling_price" 
    objects_sql += "
      , (SELECT COUNT(*) FROM Stocks WHERE (Stocks.magic_card_id = Magic_Cards.id AND Stocks.status = 'online' AND Stocks.user_id = #{@user.id})) AS online
      , (SELECT COUNT(*) FROM Stocks WHERE (Stocks.magic_card_id = Magic_Cards.id AND Stocks.status = 'depositing' AND Stocks.user_id = #{@user.id})) AS depositing
      , (SELECT COUNT(*) FROM Stocks WHERE (Stocks.magic_card_id = Magic_Cards.id AND Stocks.status = 'withdrawing' AND Stocks.user_id = #{@user.id})) AS withdrawing
      , (SELECT COUNT(*) FROM Stocks WHERE (Stocks.magic_card_id = Magic_Cards.id AND Stocks.status = 'selling' AND Stocks.user_id = #{@user.id})) AS selling
      , (SELECT COUNT(*) FROM Transactions WHERE (Transactions.magic_card_id = Magic_Cards.id AND Transactions.status = 'buying' AND Transactions.buyer_id = #{@user.id})) AS buying
      " if @user.present?
    objects_sql += " FROM Magic_Cards JOIN Magic_sets ON Magic_Cards.magic_set_id = Magic_Sets.id WHERE (Magic_Cards.name ILIKE ? OR Magic_Cards.plain_name ILIKE ?) AND disabled = false ORDER BY Magic_Cards.id ASC"
    @objects = MagicCard.find_by_sql([objects_sql, "%#{searchable(params[:search])}%", "%#{searchable(params[:search])}%"])

    @cards = [] 
    @packs = [] 
    @planars = [] 
    @vanguards = [] 
    configure_filters(true, true, false)

  end

  def livesearch
    if params[:search].empty?
      @objects = []
      render partial: 'search/live_search' and return
    end
    if params[:search].length < 3
      @objects = []
      render partial: 'search/live_search' and return
    end
    @results = MagicCard.find_by_sql(['SELECT Magic_Cards.name, Magic_Cards.plain_name
      FROM Magic_Cards
      WHERE (Magic_Cards.name ILIKE ? OR Magic_Cards.plain_name ILIKE ?) AND disabled = false
      GROUP BY Magic_Cards.name, Magic_Cards.plain_name', "%#{searchable(params[:search])}%", "%#{searchable(params[:search])}%"])
    @regexp = /#{searchable(params[:search]).replace_special_characters}/i;
    @objects =  @results.sort_by { |x| [(x.plain_name =~ @regexp), x.name.downcase] }.first(10)
    render partial: 'search/live_search'
  end

  def setsearch
    @sets = []
    @foil = "off"
    render partial: 'search/set_search' and return if params[:search].empty?
    @sets = MagicCard.find_by_sql(['SELECT Magic_Sets.name, Magic_Sets.code, Magic_Cards.object_type
      FROM Magic_Sets JOIN Magic_Cards ON Magic_Cards.magic_set_id = Magic_Sets.id
      WHERE Magic_Cards.name LIKE ? AND disabled = false
      GROUP BY Magic_Sets.name, Magic_Sets.code, Magic_Cards.object_type
      ORDER BY Magic_Sets.name', "%#{searchable(params[:search])}%",])
    render partial: 'search/set_search' and return if @sets.empty?
    (["card", "planar"].include?(@sets.first.object_type) ? @foil = "on" : @foil = "off" )
    render partial: 'search/set_search'
  end

end


