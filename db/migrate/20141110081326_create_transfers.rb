class CreateTransfers < ActiveRecord::Migration
  def change
    create_table :transfers do |t|
      t.integer :user_id
      t.integer :magic_account_id
      t.integer :wallet_depositing
      t.integer :wallet_withdrawing

      t.timestamps
    end
  end
end
