class CreateTradeHistories < ActiveRecord::Migration
  def change
    create_table :trade_histories do |t|
      t.integer :trade_queue_id
      t.integer :bot_id
      t.string :status

      t.timestamps
    end

    add_index :trade_histories, :trade_queue_id

  end
end

