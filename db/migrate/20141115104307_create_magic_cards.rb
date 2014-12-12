class CreateMagicCards < ActiveRecord::Migration
  def change
    create_table :magic_cards do |t|
      t.integer :mtgo_id
      t.string :object_type
      t.string :name
      t.string :plain_name
      t.integer :magic_set_id
      t.string :rarity
      t.boolean :foil, default: false
      t.string :collector_number
      t.string :art_version, default: "default"

      t.boolean :disabled, default: false

      t.timestamps
    end

    add_index :magic_cards, :mtgo_id, unique: true
    add_index :magic_cards, :magic_set_id
    add_index :magic_cards, :name
    add_index :magic_cards, :plain_name
    add_index :magic_cards, :object_type

  end
end


#Potential other attributes
#     t.string :casting_cost
#     t.integer :converted_mana_cost
#     t.string :card_type
#     t.string :sub_type
#     t.text :text, array: true, default: []
#     t.text :flavor_text, array: true, default: []
#     t.string :power
#     t.string :toughness
#     t.string :loyalty
#     t.string :artist
#     t.integer :gatherer_id

      
    

 