module MagicCardHelper
  def card_image(card)
    if FileTest.exist?("app/assets/images/card_images/#{card.magic_set.code}/#{card.plain_name}.hq.jpg")
      return image_tag("card_images/#{card.magic_set.code}/#{card.plain_name}.hq.jpg", class: "card-image")
    else
      return image_tag("cardback.hq.jpg", class: "card-image")
    end
  end

end
