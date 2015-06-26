class CreateTradeQueues < ActiveRecord::Migration
  def change
    create_table :trade_queues do |t|
      t.string :magic_account_name
      t.integer :magic_account_id
      t.integer :runner_id
      t.integer :bank_id
      t.string :status

      t.timestamps
    end

    add_index :trade_queues, :magic_account_name

  end
end

