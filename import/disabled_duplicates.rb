MagicCard.find_by_sql(" SELECT name, count (*) as count, magic_set_id FROM Magic_Cards GROUP BY name, magic_set_id HAVING COUNT(*) > 2 ").each do |card|
  MagicCard.where(name: card.name, magic_set_id: card.magic_set_id).each do |c|
    c.update_attribute(:disabled, true)
  end
end




