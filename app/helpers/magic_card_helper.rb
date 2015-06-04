module MagicCardHelper
  def card_image(card)
    if FileTest.exist?("app/assets/images/card_images/#{card.magic_set.code}/#{card.plain_name}.hq.jpg")
      return "card_images/#{card.magic_set.code}/#{card.plain_name}.hq.jpg"
    elsif FileTest.exist?("app/assets/images/card_images/#{card.magic_set.code}/#{card.plain_name}.hq.png")
      return "card_images/#{card.magic_set.code}/#{card.plain_name}.hq.png"
    elsif FileTest.exist?("app/assets/images/card_images/#{card.magic_set.code}/#{card.plain_name}.jpg")
      return "card_images/#{card.magic_set.code}/#{card.plain_name}.jpg"
    elsif FileTest.exist?("app/assets/images/card_images/#{card.magic_set.code}/#{card.plain_name}.png")
      return "card_images/#{card.magic_set.code}/#{card.plain_name}.png"
    elsif FileTest.exist?("app/assets/images/pack_images/#{card.name}.jpg")
      return "pack_images/#{card.name}.jpg"
    else
      return "cardback.hq.jpg"
    end
  end

  def searchable(name)
    return name.gsub(/%/,"")
               .gsub(/#/,"")
               .gsub(/\{/,"")
               .gsub(/\}/,"")
               .gsub(/\[/,"")
               .gsub(/\]/,"")
               .gsub(/\(/,"")
               .gsub(/\)/,"")
               .gsub(/\\/,"")
               .gsub(/\//,"")
  end

end
