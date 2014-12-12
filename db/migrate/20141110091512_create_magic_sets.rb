class CreateMagicSets < ActiveRecord::Migration
  def change
    create_table :magic_sets do |t|
      t.string :name
      t.string :code
      t.integer :magic_block_id

      t.timestamps null: false
    end
   	add_index :magic_sets, :name, unique: true
  	add_index :magic_sets, :code, unique: true
  end
end
