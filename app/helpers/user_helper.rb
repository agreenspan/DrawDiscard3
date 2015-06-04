module UserHelper

  private

    def account_valid?
      if params[:magic_account].empty?
        flash_message :danger, "Magic account name cannot be blank."
        return false
      elsif params[:magic_account] !~ /\A[\w+\-.]+\z/i
        flash_message :danger, "Magic account name not valid."
        return false
      elsif params[:magic_account].length < 3
        flash_message :danger, "Magic account name must contain at least 3 characters."
        return false
      else
        return true
      end
    end

    def codes_valid?
      if params[:bot_code].empty? || params[:user_code].empty?
        flash_message :danger, "MTGO codes cannot be blank."
        return false
      elsif params[:bot_code].length < 6 || params[:user_code].length < 6
        flash_message :danger, "MTGO codes must contain at least 6 characters."
        return false
      else
        return true
      end
    end

    def max_accounts?
      if current_user.magic_accounts.count == 10
        flash_message :danger, "You may only have 10 magic accounts."
        return true
      else
        return false
      end
    end

    def email_valid?
      if params[:email].empty?
        flash_message :danger, "Email address cannot be blank."
        return false
      elsif params[:email] !~ /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
        flash_message :danger, "Email address not valid."
        return false
      else
        return true
      end
    end

    def email_available?
      if User.where(email: params[:email].downcase).any?
        flash_message :danger, "Email address already in use."
        return false
      else
        return true
       end
    end

    def email_registered?
      if User.where(email: params[:email].downcase).empty?
        flash_message :danger, "No account exists with that email."
        return false
      else
        return true
       end
    end


    def password_valid?
      if params[:password].length < 8
        flash_message :danger, "Password must contain at least 8 characters."
        return false
      elsif params[:password].length > 255
        flash_message :danger, "Password must contain no more than 255 characters."
        return false
      else
        return true
      end
    end

    def confirm_password?
      if params[:password] != params[:password_confirmation]
        flash_message :danger, "Password and confirmation must match."
        return false
      else
        return true
      end
    end

    def authenticate_password?(user, password)
	  if password.blank?
        flash_message :danger, "Incorrect password."
        return false
	  end       
      if user.authenticate(password)
        return true
      else
        flash_message :danger, "Incorrect password."
        return false
      end
    end

    def associated_account?
      if @user.magic_accounts.map {|account| account.name }.include?(params[:magic_account])
        return true
      else
        flash_message :danger, "You have not added this account."
        return false
      end
    end

    def collection_column_key(col_num, dir)
      case col_num
        when "0"
          return "Magic_Cards.name "+( dir == "desc" ? "DESC" : "ASC" )
        when "1"
          return "Magic_Sets.code "+( dir == "desc" ? "DESC" : "ASC" )+", Magic_Cards.name ASC"
        when "2"
          return "object_type "+( dir == "desc" ? "DESC" : "ASC" )+", CASE "+
          rarity_filter_index.map.with_index { |value, index| "WHEN rarity = '"+value.to_s+"' THEN "+index.to_s+" "}.join("")+
          " END "+
          ( dir == "desc" ? "DESC NULLS LAST" : "ASC NULLS LAST" )+", Magic_Cards.name ASC"
        when "3"
          return "buying_price "+( dir == "desc" ? "DESC NULLS LAST" : "ASC NULLS FIRST" )
        when "4"
          return "selling_price "+( dir == "desc" ? "DESC NULLS LAST" : "ASC NULLS FIRST" )
        when "5"
          return "online "+( dir == "desc" ? "DESC NULLS LAST" : "ASC NULLS FIRST" )+", Magic_Cards.name ASC"
        when "6"
          return "depositing "+( dir == "desc" ? "DESC NULLS LAST" : "ASC NULLS FIRST" )+", Magic_Cards.name ASC"
        when "7"
          return "withdrawing "+( dir == "desc" ? "DESC NULLS LAST" : "ASC NULLS FIRST" )+", Magic_Cards.name ASC"
        when "8"
          return "selling "+( dir == "desc" ? "DESC NULLS LAST" : "ASC NULLS FIRST" )+", Magic_Cards.name ASC"
        when "9"
          return "buying "+( dir == "desc" ? "DESC NULLS LAST" : "ASC NULLS FIRST" )+", Magic_Cards.name ASC"
        else
          return "Magic_Cards.name "+( dir == "desc" ? "DESC" : "ASC" )
      end
    end

    def compile_collection_filter_sql
      params[:order] ||= { default: { column: "default", dir: "asc" } } 
      @order = [ params[:order]["0"][:column] , collection_column_key( params[:order]["0"][:column], params[:order]["0"][:dir] ) ]

      params[:foil] ||= []
      params[:rarity] ||= []
      params[:collection] ||= []
      params[:set] ||= []

      foil_filter = ""
      foil_filter = "foil" if ( params[:foil].include? ("foil") ) && ( !params[:foil].include? ("normal") )
      foil_filter = "normal" if ( !params[:foil].include? ("foil") ) && ( params[:foil].include? ("normal") )

      rarity_filter = []
      object_type_filter = []
      params[:rarity] << "vanguard" if (params[:set].include? ("VAN")) && (!params[:rarity].include? ("vanguard"))
      contains_all = true
      contains_any = false
      rarity_filter_index.each do |e|
        contains_all = false unless params[:rarity].include? (e)
        contains_any = true if params[:rarity].include? (e)
      end
      all_rarities = contains_all
      params[:rarity] << "card" if contains_any or contains_all
      object_filter_index.each do |e|
        contains_all = false unless params[:rarity].include? (e)
        contains_any = true if params[:rarity].include? (e)
      end
      if contains_any && !contains_all
        object_filter_index.each do |e|
          object_type_filter << e if params[:rarity].include? (e)
        end
        unless all_rarities
          rarity_filter_index.each do |e|
            rarity_filter << e if params[:rarity].include? (e)
          end
        end
      end

      collection_filter = []
      contains_all = true
      contains_any = false
      collection_filter_index.each do |e|
        contains_all = false unless params[:collection].include? (e)
        contains_any = true if params[:collection].include? (e)
      end
      if contains_any && !contains_all
        collection_filter_index.each do |e|
          collection_filter << e if params[:collection].include? (e)
        end
      end

      set_filter = []
      params[:set] << "VAN" if ( ( params[:rarity].include? ("vanguard") ) && ( !params[:set].include? ("vanguard") ) && ( params[:set].reject(&:blank?).any? ) )
      params[:set] << "_CON" if params[:set].include? ("CON")
      contains_all = true
      contains_any = false
      set_filter_index.each do |e|
        contains_all = false unless params[:set].include? (e)
        contains_any = true if params[:set].include? (e)
      end
      if contains_any && !contains_all
        set_filter_index.each do |e|
          set_filter << e if params[:set].include? (e)
        end
      end

      filters = []
      unless ( foil_filter == "" && rarity_filter.empty? && object_type_filter.empty? && set_filter.empty? && searchable(params[:search][:value]).length == 0 )
        filters = []
        foil_object_types = object_type_filter & ["card", "planar"]
        non_foil_object_types = object_type_filter & ["pack", "vanguard"]
        if foil_filter != ""
          filter_string = ( non_foil_object_types.any? ? "( " : "" )
          filter_string += "( ( Magic_Cards.foil = #{ ( foil_filter == 'foil' ? true : false ) } ) "
          filter_string += ( foil_object_types.any? ? "AND ( Magic_Cards.object_type IN ( #{ foil_object_types.map { |s| "'"+s+"'" }.join(', ') } ) ) ) " : ") " ) 
          filter_string += " OR ( Magic_Cards.object_type IN ( #{ non_foil_object_types.map { |s| "'"+s+"'" }.join(', ') } ) ) ) " if non_foil_object_types.any? 
          filters << filter_string
        else
          filters << "( Magic_Cards.object_type IN ( #{ object_type_filter.map { |s| "'"+s+"'" }.join(', ') } ) ) " unless object_type_filter.empty?
        end
        filters << "( Magic_Cards.rarity IN ( #{ rarity_filter.map { |s| "'"+s+"'" }.join(', ') } )
          #{ ( (object_type_filter & ["planar", "pack", "vanguard"]).any? && rarity_filter.any? ? " OR Magic_Cards.rarity IS NULL " : "" ) } ) " unless rarity_filter.empty?
        filters << "( Magic_Sets.code IN ( #{ set_filter.map { |s| "'"+s+"'" }.join(', ') } ) ) " unless set_filter.empty?
        filters << "( ( Magic_Cards.name ILIKE '%#{ searchable(params[:search][:value]).gsub(/'/,"''") }%' ) OR 
          ( Magic_Cards.plain_name ILIKE '%#{ searchable(params[:search][:value]).gsub(/'/,"''") }%' ) ) " unless searchable(params[:search][:value]).length == 0
      end

      sql_string =  "SELECT Magic_Cards.id "
      sql_string += ", (SELECT MAX(t.price) FROM Transactions as t WHERE (t.magic_card_id = Magic_Cards.id AND t.status = 'buying')) AS buying_price " if @order[0] == "3"
      sql_string += ", (SELECT MIN(t.price) FROM Transactions as t WHERE (t.magic_card_id = Magic_Cards.id AND t.status = 'selling')) AS selling_price "  if @order[0] == "4"
      sql_string += ", (SELECT COUNT(*) FROM Stocks WHERE (Stocks.magic_card_id = Magic_Cards.id AND Stocks.status = 'online' AND Stocks.user_id = #{@user.id})) AS online " if @order[0] == "5"
      sql_string += ", (SELECT COUNT(*) FROM Stocks WHERE (Stocks.magic_card_id = Magic_Cards.id AND Stocks.status = 'depositing' AND Stocks.user_id = #{@user.id})) AS depositing " if @order[0] == "6"
      sql_string += ", (SELECT COUNT(*) FROM Stocks WHERE (Stocks.magic_card_id = Magic_Cards.id AND Stocks.status = 'withdrawing' AND Stocks.user_id = #{@user.id})) AS withdrawing " if @order[0] == "7"
      sql_string += ", (SELECT COUNT(*) FROM Stocks WHERE (Stocks.magic_card_id = Magic_Cards.id AND Stocks.status = 'selling' AND Stocks.user_id = #{@user.id})) AS selling " if @order[0] == "8"
      sql_string += ", (SELECT COUNT(*) FROM Transactions WHERE (Transactions.magic_card_id = Magic_Cards.id AND Transactions.status = 'buying' AND Transactions.buyer_id = #{@user.id})) AS buying " if @order[0] == "9"
      sql_string += "FROM Magic_Cards "
      sql_string += "JOIN Magic_Sets ON Magic_Cards.magic_set_id = Magic_Sets.id " unless set_filter.empty? && @order[0] != "1"
      sql_string += "WHERE ( Magic_Cards.disabled = false ) AND ( Magic_Cards.id IN ( " 
      unless collection_filter == ["buying"]
        sql_string += "SELECT Stocks.magic_card_id "
        sql_string += "FROM Stocks JOIN Magic_Cards ON Stocks.magic_card_id = Magic_Cards.id WHERE ( Stocks.user_id = #{@user.id} ) "
        sql_string += "AND ( Stocks.status IN ( #{ collection_filter.map { |s| "'"+s+"'" }.join(', ') } ) ) " unless collection_filter.empty?
        sql_string += "GROUP BY Stocks.magic_card_id "
      end
      if collection_filter.empty? || ( collection_filter.include? ("buying") )
        sql_string += "UNION " unless collection_filter == ["buying"]
        sql_string += "SELECT Transactions.magic_card_id "
        sql_string += "FROM Transactions
          WHERE ( Transactions.buyer_id = #{@user.id} ) AND ( status = 'buying' )
          GROUP BY Transactions.magic_card_id "
      end
      sql_string += ") ) "
      sql_string += "AND #{ filters.join(" AND ") } " unless filters.empty?
      sql_string += "ORDER BY #{@order[1]} " 
      return sql_string
    end

    def transactions_column_key(col_num, dir)
      case col_num
        when "0"
          return "Magic_Cards.name "+( dir == "desc" ? "DESC" : "ASC" )
        when "1"
          return "Magic_Sets.code "+( dir == "desc" ? "DESC" : "ASC" )+", Magic_Cards.name ASC"
        when "2"
          return "Magic_Cards.object_type "+( dir == "desc" ? "DESC" : "ASC" )+", CASE "+
          rarity_filter_index.map.with_index { |value, index| "WHEN Magic_Cards.rarity = '"+value.to_s+"' THEN "+index.to_s+" "}.join("")+
          " END "+
          ( dir == "desc" ? "DESC NULLS LAST" : "ASC NULLS LAST" )+", Magic_Cards.name ASC"
        when "5"
          return "price "+( dir == "desc" ? "DESC NULLS LAST" : "ASC NULLS FIRST" )
        when "3"
          return "relation "+( dir == "desc" ? "DESC NULLS LAST" : "ASC NULLS FIRST" )
        when "4"
          return "quantity "+( dir == "desc" ? "DESC NULLS LAST" : "ASC NULLS FIRST" )
        when "6"
          return "status "+( dir == "desc" ? "DESC NULLS LAST" : "ASC NULLS FIRST" )
        when "7"
          return "start "+( dir == "desc" ? "DESC NULLS LAST" : "ASC NULLS FIRST" )
        when "8"
          return "finish "+( dir == "desc" ? "DESC NULLS LAST" : "ASC NULLS FIRST" )
        else
          return "Magic_Cards.name "+( dir == "desc" ? "DESC" : "ASC" )
      end
    end

    def compile_transactions_filter_sql
      params[:order] ||= { default: { column: "default", dir: "asc" } } 
      @order = [ params[:order]["0"][:column] , transactions_column_key( params[:order]["0"][:column], params[:order]["0"][:dir] ) ]

      params[:foil] ||= []
      params[:rarity] ||= []
      params[:relation] ||= []
      params[:status] ||= []
      params[:set] ||= []
      params[:price] ||= []
      params[:start_date] ||= []
      params[:finish_date] ||= []

      foil_filter = ""
      foil_filter = "foil" if ( params[:foil].include? ("foil") ) && ( !params[:foil].include? ("normal") )
      foil_filter = "normal" if ( !params[:foil].include? ("foil") ) && ( params[:foil].include? ("normal") )

      rarity_filter = []
      object_type_filter = []
      params[:rarity] << "vanguard" if (params[:set].include? ("VAN")) && (!params[:rarity].include? ("vanguard"))
      contains_all = true
      contains_any = false
      rarity_filter_index.each do |e|
        contains_all = false unless params[:rarity].include? (e)
        contains_any = true if params[:rarity].include? (e)
      end
      all_rarities = contains_all
      params[:rarity] << "card" if contains_any or contains_all
      object_filter_index.each do |e|
        contains_all = false unless params[:rarity].include? (e)
        contains_any = true if params[:rarity].include? (e)
      end
      if contains_any && !contains_all
        object_filter_index.each do |e|
          object_type_filter << e if params[:rarity].include? (e)
        end
        unless all_rarities
          rarity_filter_index.each do |e|
            rarity_filter << e if params[:rarity].include? (e)
          end
        end
      end

      set_filter = []
      params[:set] << "VAN" if ( ( params[:rarity].include? ("vanguard") ) && ( !params[:set].include? ("vanguard") ) && ( params[:set].reject(&:blank?).any? ) )
      params[:set] << "_CON" if params[:set].include? ("CON")
      contains_all = true
      contains_any = false
      set_filter_index.each do |e|
        contains_all = false unless params[:set].include? (e)
        contains_any = true if params[:set].include? (e)
      end
      if contains_any && !contains_all
        set_filter_index.each do |e|
          set_filter << e if params[:set].include? (e)
        end
      end

      relation_string = ""
      if (["buyer", "seller"] & params[:relation]).count == 1
        if params[:relation].include? ("buyer")
          relation_string = "( Transactions.buyer_id = #{@user.id} ) "
        else 
          relation_string = "( Transactions.seller_id = #{@user.id} ) "
        end
      else
        relation_string = "( Transactions.buyer_id = #{@user.id} OR Transactions.seller_id = #{@user.id} ) "
      end

      status_string = ""
      if (["active", "complete", "cancelled"] & params[:status]).count > 0 && (["active", "complete", "cancelled"] & params[:status]).count < 3
        status_filters = []
        if params[:status].include? ("active")
          if (["buyer", "seller"] & params[:relation]).count != 1
            status_filters << "( status = 'buying' ) "
            status_filters << "( status = 'selling' ) "
          elsif params[:relation].include? ("buyer")
            status_filters << "( status = 'buying' ) "
          else
            status_filters << "( status = 'selling' ) "
          end
        end
        if params[:status].include? ("complete")
          status_filters << "( status = 'finished' ) "
        end
        if params[:status].include? ("cancelled")
          status_filters << "( status = 'cancelled' ) "
        end
        status_string = "AND ( #{status_filters.join('OR ')} ) "
      end

      price_string = ""
      case params[:price][0]
      when "equals"
        price_string = "AND ( price = #{ params[:price][1].to_f.abs } ) " 
      when "less_than"
        price_string = "AND ( price <= #{ params[:price][1].to_f.abs } ) "
      when "greater_than"
        price_string = "AND ( price >= #{ params[:price][1].to_f.abs } ) "
      when "between"
        larger = [params[:price][1].to_f.abs, params[:price][2].to_f.abs].max 
        smaller = [params[:price][1].to_f.abs, params[:price][2].to_f.abs].min
        price_string = "AND ( ( price >= #{ smaller } ) AND ( price <= #{ larger } ) ) "
      end

      start_date_string = ""
      case params[:start_date][0]
      when "equals"
        date = Timeliness.parse( params[:start_date][1] )
        date ||= Date.today
        start_date_string = "AND ( ( start >= '#{ (date).to_datetime.to_formatted_s(:db) }' ) AND ( start <= '#{ (date+1).to_datetime.to_formatted_s(:db) }' ) )" 
      when "less_than"
        date = Timeliness.parse( params[:start_date][1] )
        date ||= Date.today
        start_date_string = "AND ( start <= '#{ (date+1).to_datetime.to_formatted_s(:db) }' ) "
      when "greater_than"
        date = Timeliness.parse( params[:start_date][1] )
        date ||= Date.parse("01/01/2015") 
        start_date_string = "AND ( start >= '#{ (date).to_datetime.to_formatted_s(:db) }' ) "
      when "between"
        larger = [ Timeliness.parse( params[:start_date][1], :date ), Timeliness.parse( params[:start_date][2], :date ) ].compact.max 
        larger ||= Date.today
        smaller = [ Timeliness.parse( params[:start_date][1], :date ), Timeliness.parse( params[:start_date][2], :date ) ].compact.min
        smaller ||= Date.parse("01/01/2015") 
        start_date_string = "AND ( ( start >= '#{ (smaller).to_datetime.to_formatted_s(:db) }' ) AND ( start <= '#{ (larger+1).to_datetime.to_formatted_s(:db) }' ) ) "
      end

      finish_date_string = ""
      case params[:finish_date][0]
      when "equals"
        date = Timeliness.parse( params[:finish_date][1] )
        date ||= Date.today
        finish_date_string = "AND ( ( finish >= '#{ (date).to_datetime.to_formatted_s(:db) }' ) AND ( finish <= '#{ (date+1).to_datetime.to_formatted_s(:db) }' ) )" 
      when "less_than"
        date = Timeliness.parse( params[:finish_date][1] )
        date ||= Date.today
        finish_date_string = "AND ( finish <= '#{ (date+1).to_datetime.to_formatted_s(:db) }' ) "
      when "greater_than"
        date = Timeliness.parse( params[:finish_date][1] )
        date ||= Date.parse("01/01/2015") 
        finish_date_string = "AND ( finish >= '#{ (date).to_datetime.to_formatted_s(:db) }' ) "
      when "between"
        larger = [ Timeliness.parse( params[:finish_date][1], :date ), Timeliness.parse( params[:finish_date][2], :date ) ].compact.max 
        larger ||= Date.today
        smaller = [ Timeliness.parse( params[:finish_date][1], :date ), Timeliness.parse( params[:finish_date][2], :date ) ].compact.min
        smaller ||= Date.parse("01/01/2015") 
        finish_date_string = "AND ( ( finish >= '#{ (smaller).to_datetime.to_formatted_s(:db) }' ) AND ( finish <= '#{ (larger+1).to_datetime.to_formatted_s(:db) }' ) ) "
      end

      filters = []
      foil_object_types = object_type_filter & ["card", "planar"]
      non_foil_object_types = object_type_filter & ["pack", "vanguard"]
      if foil_filter != ""
        filter_string = ( non_foil_object_types.any? ? "( " : "" )
        filter_string += "( ( Magic_Cards.foil = #{ ( foil_filter == 'foil' ? true : false ) } ) "
        filter_string += ( foil_object_types.any? ? "AND ( Magic_Cards.object_type IN ( #{ foil_object_types.map { |s| "'"+s+"'" }.join(', ') } ) ) ) " : ") " ) 
        filter_string += " OR ( Magic_Cards.object_type IN ( #{ non_foil_object_types.map { |s| "'"+s+"'" }.join(', ') } ) ) ) " if non_foil_object_types.any? 
        filters << filter_string
      else
        filters << "( Magic_Cards.object_type IN ( #{ object_type_filter.map { |s| "'"+s+"'" }.join(', ') } ) ) " unless object_type_filter.empty?
      end
      filters << "( Magic_Cards.rarity IN ( #{ rarity_filter.map { |s| "'"+s+"'" }.join(', ') } )
        #{ ( (object_type_filter & ["planar", "pack", "vanguard"]).any? && rarity_filter.any? ? " OR Magic_Cards.rarity IS NULL " : "" ) } ) " unless rarity_filter.empty?
      filters << "( Magic_Sets.code IN ( #{ set_filter.map { |s| "'"+s+"'" }.join(', ') } ) ) " unless set_filter.empty?
      filters << "( ( Magic_Cards.name ILIKE '%#{ searchable(params[:search][:value]).gsub(/'/,"''") }%' ) OR 
        ( Magic_Cards.plain_name ILIKE '%#{ searchable(params[:search][:value]).gsub(/'/,"''") }%' ) ) " unless searchable(params[:search][:value]).length == 0
      filters << "( Magic_Cards.mtgo_id = #{ params[:mtgo_id].to_i } ) " unless params[:mtgo_id].nil?
      filters << "( Magic_Cards.disabled = false ) "
      card_filter_string = ""
      card_filter_string += "AND ( Transactions.magic_card_id IN ( SELECT Magic_Cards.id FROM Magic_Cards "
      card_filter_string += "JOIN Magic_Sets ON Magic_Cards.magic_set_id = Magic_Sets.id " unless set_filter.empty?
      card_filter_string += "WHERE #{ filters.join(" AND ") } ) ) "

      sql_string = "
        SELECT Magic_Cards.mtgo_id, Magic_Cards.name, Magic_Cards.foil, Magic_Cards.rarity, Magic_Cards.object_type, Magic_Sets.code, t.price, t.quantity, t.status, t.truncated_start as start, t.truncated_finish as finish, t.relation
        FROM (
          SELECT Transactions.magic_card_id, Transactions.price, COUNT (*) as quantity
          , CASE WHEN Transactions.status in ('buying', 'selling') THEN 'active' ELSE Transactions.status END as status 
          , DATE_TRUNC('day', Transactions.start) as truncated_start, DATE_TRUNC('day', Transactions.finish) as truncated_finish
          , CASE WHEN Transactions.buyer_id = #{@user.id} THEN 'Buyer' WHEN Transactions.seller_id = #{@user.id} THEN 'Seller' END as relation "
      sql_string += ", Magic_Cards.mtgo_id, Magic_Cards.name, Magic_Cards.foil, Magic_Cards.rarity, Magic_Cards.object_type " if ["0", "1", "2"].include? (@order[0]) 
      sql_string += ", Magic_Sets.code " if @order[0] == "1" 
      sql_string += "FROM Transactions "
      sql_string += "JOIN Magic_Cards ON Transactions.magic_card_id = Magic_Cards.id " if ["0", "1", "2"].include? (@order[0]) 
      sql_string += "JOIN Magic_Sets ON Magic_Cards.magic_set_id = Magic_Sets.id " if @order[0] == "1"  
      sql_string += "WHERE "
      sql_string += relation_string
      sql_string += status_string
      sql_string += price_string 
      sql_string += start_date_string 
      sql_string += finish_date_string 
      sql_string += card_filter_string 
      sql_string += "GROUP BY Transactions.magic_card_id, Transactions.price, Transactions.status, truncated_start, truncated_finish, relation "
      sql_string += ", Magic_Cards.mtgo_id, Magic_Cards.name, Magic_Cards.foil, Magic_Cards.rarity, Magic_Cards.object_type " if ["0", "1", "2"].include? (@order[0]) 
      sql_string += ", Magic_Sets.code " if @order[0] == "1" 
      sql_string += "ORDER BY #{ @order[1].gsub('start', 'truncated_start').gsub('finish', 'truncated_finish') } "
      sql_string += "LIMIT #{params[:length].to_i} OFFSET #{params[:start].to_i} ) AS t  
        JOIN Magic_Cards ON t.magic_card_id = Magic_Cards.id JOIN Magic_Sets ON Magic_Cards.magic_set_id = Magic_Sets.id
        ORDER BY #{@order[1]} "

      @count_sql_string = "SELECT Transactions.magic_card_id, Transactions.price, COUNT (*) as quantity, Transactions.status 
        , DATE_TRUNC('day', Transactions.start) as truncated_start, DATE_TRUNC('day', Transactions.finish) as truncated_finish 
        , CASE WHEN Transactions.buyer_id = #{@user.id} THEN 'Buyer' WHEN Transactions.seller_id = #{@user.id} THEN 'Seller' END as relation "
      @count_sql_string += "FROM Transactions "
      @count_sql_string += "WHERE "
      @count_sql_string += relation_string
      @count_sql_string += status_string
      @count_sql_string += price_string 
      @count_sql_string += start_date_string 
      @count_sql_string += finish_date_string 
      @count_sql_string += card_filter_string 
      @count_sql_string += "GROUP BY Transactions.magic_card_id, Transactions.price, Transactions.status, truncated_start, truncated_finish, relation "

      return sql_string
    end

end
