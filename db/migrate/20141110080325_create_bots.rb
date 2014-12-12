class CreateBots < ActiveRecord::Migration
  def change
    create_table :bots do |t|
      t.string :name
      t.string :role
      t.integer :wallet, default: 0

      t.timestamps
    end
  end
end
