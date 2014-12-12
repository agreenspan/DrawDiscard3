class CreateTradeQueues < ActiveRecord::Migration
  def change
    create_table :trade_queues do |t|
      t.integer :magic_account_id
      t.integer :runner_id
      t.integer :bank_id
      t.string :status
      t.string :transfer_id
      t.boolean :cancelled, default: false 
      t.text :history, array: true, default: []

      t.timestamps
    end
  end
end
