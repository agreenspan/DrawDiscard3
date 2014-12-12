class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :account_status, default: "active"

      t.string :email
      t.string :password_digest

      t.string :confirmation_code
      t.boolean :confirmed, default: false

      t.string :user_code
      t.string :bot_code
      t.integer :bot_id

      t.decimal :wallet, scale: 3, precision: 15, default: 0.000

      t.timestamps 
    end

    add_index :users, :email, unique: true

  end
end
