class CreatePages < ActiveRecord::Migration
  def change
    create_table :pages do |t|
      t.string :content
      t.integer :number
      t.references :chapter

      t.timestamps
    end
  end
end
