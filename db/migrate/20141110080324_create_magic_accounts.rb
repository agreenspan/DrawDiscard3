class CreateMagicAccounts < ActiveRecord::Migration
  def change
    create_table :magic_accounts do |t|
      t.integer :user_id
      t.string :name
      t.integer :tickets_depositing, default: 0
      t.integer :tickets_withdrawing, default: 0

      t.timestamps
    end

    add_index :magic_accounts, :user_id

  end
end
