class CreateBots < ActiveRecord::Migration
  def change
    create_table :bots do |t|
      t.string :name
      t.string :password
      t.string :role
      t.string :status
      t.integer :wallet, default: 0

      t.timestamps
    end
  end
end
