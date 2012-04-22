class CreateChapters < ActiveRecord::Migration
  def change
    create_table :chapters do |t|
      t.string :title
      t.string :introduction
      t.references :book

      t.timestamps
    end
  end
end
