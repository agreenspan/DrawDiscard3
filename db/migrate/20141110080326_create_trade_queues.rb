class CreateTradeQueues < ActiveRecord::Migration
  def change
    create_table :trade_queues do |t|
      t.integer :magic_account_id
      t.integer :runner_id
      t.integer :bank_id
      t.string :status
      t.text :history

      t.timestamps
    end
  end
end
