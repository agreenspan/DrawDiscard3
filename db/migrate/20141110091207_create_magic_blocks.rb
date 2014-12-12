class CreateMagicBlocks < ActiveRecord::Migration
  def change
    create_table :magic_blocks do |t|
      t.string :name

      t.timestamps
    end
    add_index :magic_blocks, :name, unique: true
  end
end
