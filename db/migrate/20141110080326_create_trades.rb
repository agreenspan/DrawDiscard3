class CreateTrades < ActiveRecord::Migration
  def change
    create_table :trades do |t|
      t.string :magic_account_name
      t.integer :magic_account_id
      t.integer :runner_id
      t.integer :bank_id
      t.string :status

      t.timestamps
    end

    add_index :trades, :magic_account_name

  end
end

