module MagicSetHelper

  def full_set_title_image(set, style)
    if FileTest.exist?("app/assets/images/set_titles/full/#{set.code}.png")
      return image_tag("set_titles/full/#{set.code}.png", alt: set.name, title: set.name, style: style)  
    else
      return "#{set.name}"
    end
  end

  def set_title_image(set, style)
    if FileTest.exist?("app/assets/images/set_titles/#{set.code}.png")
      return image_tag("set_titles/#{set.code}.png", alt: set.name, title: set.name, style: style)  
    else
      return "#{set.name}"
    end
  end

  def set_rarity_image(set_code, rarity)
    case rarity
      when "special"
        return "set_icons/#{set_code.downcase}_special.png"
      when "mythic"
        return "set_icons/#{set_code.downcase}_mythic.png"
      when "rare"
        return "set_icons/#{set_code.downcase}_rare.png"
      when "uncommon"
        return "set_icons/#{set_code.downcase}_uncommon.png"    
      else
        return "set_icons/#{set_code.downcase}_common.png"    
    end
  end

  def rarity_number(rarity)
    case rarity
      when "planar"
        return 0
      when "special"
        return 1
      when "mythic"
        return 2
      when "rare"
        return 3
      when "uncommon"
        return 4    
      when "common"
        return 5    
      else
        return 6    
    end
  end

  def object_filter_index
    return ['card', 'planar', 'pack', 'vanguard']
  end

  def rarity_filter_index
    return ['special', 'mythic', 'rare', 'uncommon', 'common']
  end

  def collection_filter_index
    return ['online', 'depositing', 'withdrawing', 'selling', 'buying']
  end

  def set_filter_index
    return [
      "MM2", "DTK", "FRF",
      "KTK", "M15", "JOU", "BNG", "THS", "M14", "MMA", "DGM", "GTC", "RTR", "M13", "AVR", "DKA", "ISD", "M12",
      "NPH", "MBS", "SOM", "M11", "ROE", "WWK", "ZEN", "M10", "ARB", "_CON", "CON", "ALA", "EVE", "SHM", "MOR",
      "LRW", "10E", "FUT", "PLC", "TSB", "TSP", "CSP", "DIS", "GPT", "RAV", "9ED", "SOK", "BOK", "CHK", "5DN",
      "DST", "MRD", "8ED", "SCG", "LGN", "ONS", "JUD", "TOR", "OD",  "AP",  "7E",  "PS",  "IN",  "PR",  "NE",
      "MM",  "UD",  "UL",  "UZ",  "EX",  "ST",  "TE",  "WL",  "VI",  "MI",  "VMA", "ME4", "ME3", "ME2", "MED", 
      "C14", "C13", "CMD", "PC2", "PC1", "PD3", "PD2", "H09", "V14", "V13", "V12", "V11", "V10", "V09", "DRB",
      "DDL", "DDM", "DDK", "DDJ", "DDI", "DDH", "TD2", "DDG", "DDF", "DDE", "DDD", "DDC", "DD2", "EVG", "TD0",
      "PRM", "VAN"
    ]
  end

  def configure_filters(count_packs, include_set_filters, include_planar_rarity)
    #filters
    @filters = Hash.new

    @filters[:on]= Hash.new
    @filters[:on][:on] = false
    @filters[:on][:foil] = false
    @filters[:on][:rarity] = false
    @filters[:on][:collection] = false
    @filters[:on][:set] = false

    @filters[:foil] = Hash.new
    @filters[:foil][:normal] = 0
    @filters[:foil][:foil] = 0

    @filters[:rarity] = Hash.new
    @filters[:rarity][:planar] = 0
    @filters[:rarity][:special] = 0
    @filters[:rarity][:mythic] = 0
    @filters[:rarity][:rare] = 0
    @filters[:rarity][:uncommon] = 0
    @filters[:rarity][:common] = 0
    @filters[:rarity][:basic] = 0

    @filters[:collection] = Hash.new
    @filters[:collection][:online] = [0, "DrawDiscard", "DD.png"]
    @filters[:collection][:depositing] = [0, "Depositing", "arrowDD.png"]
    @filters[:collection][:withdrawing] = [0, "Withdrawing", "arrowM.png"]
    @filters[:collection][:selling] = [0, "Selling", "forSale.png"]
    @filters[:collection][:buying] = [0, "Buying", "bids.png"]

    @filters[:set] = Hash.new

    if @user.present?
      @objects.each do |object|
        if include_set_filters
          @filters[:set][object.code.to_sym] ||= []
          @filters[:set][object.code.to_sym][0] = @filters[:set][object.code.to_sym][0].to_i + 1 
          @filters[:set][object.code.to_sym][1] ||= object.set_name
        end
        case object.object_type
          when 'card'
            @cards << object
            ( object.foil ? @filters[:foil][:foil] += 1 : @filters[:foil][:normal] += 1 )
            @filters[:rarity][object.rarity.to_sym] += 1
            @filters[:collection][:online][0] += object.online
            @filters[:collection][:depositing][0] += object.depositing
            @filters[:collection][:withdrawing][0] += object.withdrawing
            @filters[:collection][:selling][0] += object.selling
            @filters[:collection][:buying][0] += object.buying
          when 'pack'
            @packs << object
            if count_packs
              @filters[:collection][:online][0] += object.online
              @filters[:collection][:depositing][0] += object.depositing
              @filters[:collection][:withdrawing][0] += object.withdrawing
              @filters[:collection][:selling][0] += object.selling
              @filters[:collection][:buying][0] += object.buying
            end
          when 'planar'
            @planars << object
            ( object.foil ? @filters[:foil][:foil] += 1 : @filters[:foil][:normal] += 1 )
            @filters[:rarity][:planar] += 1 if include_planar_rarity
            @filters[:collection][:online][0] += object.online
            @filters[:collection][:depositing][0] += object.depositing
            @filters[:collection][:withdrawing][0] += object.withdrawing
            @filters[:collection][:selling][0] += object.selling
            @filters[:collection][:buying][0] += object.buying
          when 'vanguard'
            @vanguards << object
            @filters[:collection][:online][0] += object.online
            @filters[:collection][:depositing][0] += object.depositing
            @filters[:collection][:withdrawing][0] += object.withdrawing
            @filters[:collection][:selling][0] += object.selling
            @filters[:collection][:buying][0] += object.buying
        end
      end
    else
      @objects.each do |object|
        if include_set_filters
          @filters[:set][object.code.to_sym] ||= []
          @filters[:set][object.code.to_sym][0] = @filters[:set][object.code.to_sym][0].to_i + 1 
          @filters[:set][object.code.to_sym][1] ||= object.set_name
        end
        case object.object_type
          when 'card'
            @cards << object
            ( object.foil ? @filters[:foil][:foil] += 1 : @filters[:foil][:normal] += 1 )
            @filters[:rarity][object.rarity.to_sym] += 1
          when 'pack'
            @packs << object
          when 'planar'
            @planars << object
            ( object.foil ? @filters[:foil][:foil] += 1 : @filters[:foil][:normal] += 1 )
            @filters[:rarity][:planar] += 1
          when 'vanguard'
            @vanguards << object
        end
      end
    end
    @filters.each do |filter_key, filter_labels|
      filter_count = 0
      if [:collection, :set].include?(filter_key)
        filter_labels.each do |label_key , value|
          filter_count += 1 if value[0] > 0
        end
        @filters[:on][:collection] = true if (filter_key == :collection && filter_count > 0)
      elsif filter_key != :on
        filter_labels.each do |label_key , value|
          filter_count += 1 if value > 0
        end
      end
      @filters[:on][filter_key] = true if filter_count > 1
    end

  end

end


