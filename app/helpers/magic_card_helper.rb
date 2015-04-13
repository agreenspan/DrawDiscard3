module MagicCardHelper
  def card_image(card)
    if FileTest.exist?("app/assets/images/card_images/#{card.magic_set.code}/#{card.plain_name}.hq.jpg")
      return "card_images/#{card.magic_set.code}/#{card.plain_name}.hq.jpg"
    else
      return "cardback.hq.jpg"
    end
  end

end
