class CreateMagicAccounts < ActiveRecord::Migration
  def change
    create_table :magic_accounts do |t|
      t.integer :user_id
      t.string :name

      t.integer :wallet, default: 0

      t.timestamps
    end

    add_index :magic_accounts, :user_id

  end
end
