class CreateStocks < ActiveRecord::Migration
  def change
    create_table :stocks do |t|
      t.integer :user_id
      t.integer :magic_account_id
      t.integer :bot_id
      t.integer :magic_card_id
      t.string :status

      t.timestamps
    end

    add_index :stocks, [:user_id, :magic_card_id]

  end
end




