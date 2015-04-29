class CreateTransactions < ActiveRecord::Migration
  def change
    create_table :transactions do |t|
	  	t.integer :buyer_id
	  	t.integer :seller_id
	  	t.integer :stock_id
	  	t.integer :magic_card_id
	  	t.decimal :price, scale: 3, precision: 15
	  	t.datetime :start
	 	  t.datetime :finish
	 	  t.string :status

      t.timestamps
    end

    add_index :transactions, [:buyer_id, :status]
    add_index :transactions, [:seller_id , :status]
    add_index :transactions, [:magic_card_id, :status, :price]
    
  end
end
